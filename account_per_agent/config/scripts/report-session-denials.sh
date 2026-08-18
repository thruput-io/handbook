#!/usr/bin/env bash
set -uo pipefail

# Stop hook: after every turn, report any tool call the permission layer
# refused during that turn.
#
# Under dontAsk a refusal is silent to the operator -- the agent is told no,
# adapts or stops, and nothing surfaces the fact that a legitimate command is
# missing from the allow list. A report you have to remember to run is a report
# nobody runs, so this pushes rather than waits: the summary lands in the
# session output, and a line is appended to a shared log for unattended runs.
#
# Stop rather than PermissionDenied, which never fires here: that event covers
# auto-mode denials only. Measured -- PermissionDenied and PermissionRequest
# were wired to a logger, a denial was provoked, and the log stayed empty,
# while Stop fired every time. Stop also receives transcript_path, which is
# where the denial is actually recorded.

LOG="${CLAUDE_DENIAL_LOG:-/Users/Shared/claude-denials.log}"

python3 -c '
import json, os, sys, re, datetime
from collections import Counter

try:
    event = json.load(sys.stdin)
except Exception:
    sys.exit(0)          # a broken reporter must never disturb the session

path = event.get("transcript_path")
if not path or not os.path.exists(path):
    sys.exit(0)

DENIAL = re.compile(r"Permission to use (\w+) has been denied", re.I)

# A denial names the tool but not the command; the command lives in the
# tool_use the result answers, so the two are joined by tool_use_id.
uses, denied = {}, Counter()
try:
    lines = open(path, errors="replace").read().splitlines()
except OSError:
    sys.exit(0)

for line in lines:
    try:
        e = json.loads(line)
    except Exception:
        continue
    msg = e.get("message") or {}
    content = msg.get("content")
    if not isinstance(content, list):
        continue
    for b in content:
        if not isinstance(b, dict):
            continue
        if b.get("type") == "tool_use":
            ti = b.get("input") or {}
            uses[b.get("id")] = (b.get("name", "?"),
                                 ti.get("command") or ti.get("file_path") or "")
        elif b.get("type") == "tool_result":
            c = b.get("content")
            text = c if isinstance(c, str) else json.dumps(c)
            m = DENIAL.search(text or "")
            if not m:
                continue
            tool, detail = uses.get(b.get("tool_use_id"), (m.group(1), ""))
            denied[(tool, " ".join(str(detail).split())[:120])] += 1

if not denied:
    sys.exit(0)

user = os.environ.get("USER", "?")
stamp = datetime.datetime.now().astimezone().isoformat(timespec="seconds")

# Appended for unattended runs. Best effort: losing a log line matters less
# than interfering with the session.
log = os.environ.get("CLAUDE_DENIAL_LOG", "/Users/Shared/claude-denials.log")
try:
    with open(log, "a") as fh:
        for (tool, detail), n in denied.items():
            fh.write("\t".join([stamp, user, str(n), tool, detail]) + "\n")
except OSError:
    pass

# ...and surfaced now, so it is seen without anyone remembering to look.
out = ["", "Permission denials this turn (%s) -- not in the allow list:" % user]
for (tool, detail), n in denied.most_common():
    out.append("  %dx %s: %s" % (n, tool, detail))
out.append("  Allow with a rule in config/claude/settings.json, "
           "or review: report_denied_tools.sh")
print("\n".join(out), file=sys.stderr)
' || true

exit 0
