#!/usr/bin/env bash
set -uo pipefail

LIB_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "${LIB_DIR}/lib.sh"

# Reports tool calls the permission layer refused, across every agent, so the
# allow list in config/claude/settings.json can be tuned from what agents
# actually needed rather than from what someone guessed they would need.
#
# Why a report and not a hook: the PermissionDenied hook event fires only for
# auto-mode denials. Under dontAsk -- the mode this fleet runs -- it never
# fires. Measured, not assumed: both PermissionDenied and PermissionRequest
# were wired to a logger, a denial was provoked, and the log stayed empty.
#
# Denials are recorded in each session transcript instead, which is better for
# this purpose anyway: it is retrospective, so it covers every session that has
# already run rather than only sessions started after a hook was installed.
#
# Under dontAsk a refusal is otherwise invisible to the operator. The agent is
# told no, adapts or stops, and nothing in the fleet reports that a legitimate
# command is missing from the list -- every check keeps passing while agents
# quietly work around gaps.




# Same agent derivation as the provisioning scripts: members of the developers
# group that are not administrators.
AGENTS="${AGENTS:-}"
if [[ -z "${AGENTS}" ]]; then
  for u in $(dscl . -list /Users 2>/dev/null); do
    user_in_group "${u}" "${DEVELOPERS_GROUP}" || continue
    user_in_group "${u}" "${ADMINS_GROUP}" && continue
    AGENTS="${AGENTS:+${AGENTS} }${u}"
  done
fi
[[ -n "${AGENTS}" ]] || { echo "No agent accounts found" >&2; exit 2; }

SINCE_DAYS="${SINCE_DAYS:-30}"

for agent in ${AGENTS}; do
  printf '\n\033[1m%s\033[0m\n' "${agent}"

  # Python walks the tree rather than bash: macOS ships bash 3.2, which has no
  # mapfile/readarray, and transcript paths contain spaces (they are derived
  # from project directory names), so a plain word-split list is unsafe.
  sudo python3 - "${BASE_DIR}/${agent}/.claude/projects" "${SINCE_DAYS}" <<'PY'
import json, sys, re, os, time
from collections import Counter

DENIAL = re.compile(r"Permission to use (\w+) has been denied", re.I)

root, since_days = sys.argv[1], int(sys.argv[2])
cutoff = time.time() - since_days * 86400

paths = []
for dirpath, _dirs, names in os.walk(root):
    for n in names:
        if not n.endswith(".jsonl"):
            continue
        p = os.path.join(dirpath, n)
        try:
            if os.path.getmtime(p) >= cutoff:
                paths.append(p)
        except OSError:
            pass

if not paths:
    print(f"  no sessions in the last {since_days} days")
    raise SystemExit(0)

# Two passes per file: collect tool_use blocks by id, then find the results that
# refer to them. A denial names the tool but not the command; the command lives
# in the tool_use the result answers, so the two have to be joined by id.
counts, examples = Counter(), {}

for path in paths:
    uses = {}
    try:
        lines = open(path, errors="replace").read().splitlines()
    except OSError:
        continue

    for line in lines:
        try:
            e = json.loads(line)
        except Exception:
            continue
        msg = e.get("message") or {}
        for block in (msg.get("content") or []) if isinstance(msg.get("content"), list) else []:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use":
                ti = block.get("input") or {}
                uses[block.get("id")] = (
                    block.get("name", "?"),
                    ti.get("command") or ti.get("file_path") or "",
                )
            elif block.get("type") == "tool_result":
                content = block.get("content")
                text = content if isinstance(content, str) else json.dumps(content)
                m = DENIAL.search(text or "")
                if not m:
                    continue
                tool, detail = uses.get(block.get("tool_use_id"), (m.group(1), ""))
                # Group by the leading word of the command -- that is the unit an
                # allow rule is written against (Bash(curl *)), so counting whole
                # command lines would scatter one missing rule across many rows.
                key = (tool, (detail.split() or [""])[0])
                counts[key] += 1
                examples.setdefault(key, " ".join(detail.split())[:90])

if not counts:
    print("  no denials recorded")
else:
    print(f"  {'count':>5}  {'tool':<8} {'command':<12} example")
    for (tool, cmd), n in counts.most_common():
        print(f"  {n:>5}  {tool:<8} {cmd:<12} {examples[(tool, cmd)]}")
PY
done

printf '\nAdd a rule to config/claude/settings.json for anything an agent legitimately needs, e.g. Bash(curl *)\n'
