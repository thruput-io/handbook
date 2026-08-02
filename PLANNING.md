# Planning Mode Rules

- These rules are **activated** when **in planning mode** and can be ignored when not planning mode.
- This document supplement higher-priority system, security, repository, and user instructions.
- This document **overrides** planning mode constraints be allowing
  - Creation of a doc / plans/{planning-name} folder
  - CRUD of any file inside that folder
  - Creating a branch for the changes and committing to it
    - Usage of tools

## Folder Structure

### New plan

doc/plans/{plan-name}/001-{plan-name}.md doc/plans/{plan-name}/tests/{test-name}/{files...}
doc/plans/{plan-name}/research/{report-name}/{files...}
doc/pland/{plan-name}/progress/{plan-name-progress-{date-branch}.md

### Revised plans

If plan already exists and has been merged to main. Always make a new revision of the plan. Plans should be complete and
stand-alone, not deltas to prior plan. doc/plans/{plan-name}/{pland-version (002 for first update)}-{plan-name}.md

---

## Plan Disposition

### Implementing Agent Instructions on the following plana like this

Guidelines on the following plan, when to stop guidance, typically link to separate document.

### Background

#### Goals

Prioritized numbered list of goals that implementation of this plan should meet.

### Summary

**Short** execution plan outline.

### References

#### Tracer bullet tests

Links to test cases created to prove/disapprove hypotheseis during the elaboration phase.

#### Research

List of ALL research performed during making one of these plans, each entry should have the form:

##### Question seeking answer

###### The short answer (preferable yes/no)

###### Link to a research report

#### Rejected Alternatives

Rejected alternatives to this plan. Alternatives scope can be both for the whole and part of the existing plan.

##### Alternative title

Description of alternative solution and why it was rejected.

### Discussions

list of ALL non-trivial decisions talken during making ofd this plan.

### Execution Plan

Step-by-step implementation plan, optimized for *agents* to understand and follow. \
Each plan should be divided into milestones. Each milestone should deliver on at least one goal and should be verifiable
by a test, test name names as a human-readable sentence, should be documented
---

## Imperative Boundaries

1. **No Quick Plans** – Follow and enforce 'Way of working': **do not** write any plans on your own initiative. Instead,
   patiently guiding human through the 'Way of Working', having a mutual and completely missunderstandable 'phase' is
   always more important than advancing to the next phase.
3. **No Unsolicited Scope**: DO NOT add extra features or expand scope without explicit human consent. Always prefer the
   simple solutions.
3. **No Permission Seeking on Exit**: NEVER ask for permission to exit planning mode or to start implementation.
4. **No undocumented exploration** Never leave any activity of checking, clarifying, or asking undocumented.
5. **Merged Plans are immutable** When a plan has been merged to the main branch, it is readonly.

## Imperative: Rules

1. **Complete Transparency**: Explain INTENT with every ACTION before EXECUTING. Never leave human with doubts of your
   current activity.
2. **Log activity**: Negative AND positive findings MUST be logged under 'References'. The discussion itself is a
   valuable artifact for later retrieval. They back the architecture paths and will save valuable time in the future.
3. **Commit Often and Without Human Intervention**: Save and commit plan, research reports, and test cases (including
   negative or abandoned explorations) inside the planning folder as soon as they complete.
5. **Prefer Code**: When asked a question or if you are being uncertain, use subagents for verifying truth with a
   test-case, if you cannot come up with a test case,\
   make research by searching code base and/or web.
6. **Thourough and Parallel** Use subagents for test-cases and research. For research, instruct first level subagent to
   use second level subagents if new paths to explore are found.\
   Prioritize removing doubts and responsiveness to human over saving resources.

If a question can be answered by writing a test, YOU MUST do so, write it inside `docs/plans/{session-name}/tests/`. Do
not make ad-hoc or uncleaned test scripts 6. **Git History**: Commit the plan document frequently to preserve
checkpoints that human can revert to

7. **Docs Folder Editable**: There are no restrictions on tools, and the planning session folder is always editable.

*

## Planning Phase 1 – Preparations

### Expectations

Find a good name of a plan by asking human relentlessly about the goals of the plan. The plan name should encompass the
main goal, it should not contain anything from a solution. Solutions are volatile and many, but the basic problem being
solved will stay until solved. Limit scope, humans always try to cram too much in one single plan. Suggest saving parts
of the scope for another plan. Good Name ↔ Bad Name End User Authentication ↔ OAuth2 Client Lib // No technology
references Memory Persistence ↔ MemQ implementation // No product names Basic Automated Builds ↔ Build pipeline and Test
Coverage Enforcement // *Limit* scope. *One* problem per plan.

### Execution

1. Find a good name for land by collecting goals and limiting the scope. (skip on update)
2. Verify that you have all permissions needed for doing among other things:

- Read all (ls, cat, tail, head, grep, etc.)) files in repo
- Create the planning folder in plans (ASK human for name)
- Any git command
- Create update, delete anything within the plan-folder
- Use subagents for web research and permission needed to do so

3. If you do not have permissions, ask a human with *one* question to get it.
4. Make sure git is up to date and clean
5. Read guidelines and ALL ADRs. ADRs are located in the doc / adrs folder. Always start reading from the highest number, ignore
   any conficts as you progress downwards in numbering.
6. Create a planning branch with plan version (001-create-test-vm) (on update bump number if merged)
7. Create a planning folder (create-test-vm) (skip on update)
8. Create plan document with headers level according to 'Plan Disposition'
9. Document discussion and goals that surfaced during naming.

### Criteria for Starting with 'Ideation & Exploration'

1. Planning document is created and ready to be filled in. At least one goal is already in it.
2. Decisions taken, tests, and research you spun off have returned with results.
3. All necessary permissions are there and verified. You need to be able to verify **realism** of the plan to be
   created.\
   If you cannot, you must **stop** and **resolve** permission issues before continuing.

## Planning Phase 2 – Ideation & Exploration

### Expectations

- In the beginning do ask about details, try to capture the overall goals. Having clear goals is the most important result 
  of this phase.
- Do research on finding libs or tools that already solve the problem at hand.
- Experiment with findings in test cases. Are found tools and libs easy to use? can they be used to lessen the scope of
  the plan?
- Use your knowledge to prevent humans from inventing the wheel again. Cut the scope of the plan by using the correct
  tooling is an awesome accomplishment.
- Limited and Focused scope. A plan should solve EXACTLY one a problem. PR reviewers will never accept a plan that\  
  be split into smaller chunks and still bring value.

### Execution

- Do not create or draft 'Execution Plan'.
- For each asked question, provide your recommended answer.
- Summary should logically describe how goals are achieved.
- Assumptions should be verified and turned into facts.
- By asking one question per turn you will resolve ambiguities and clarify intent
- You MUST search for alternative solutions. If found to interrupt human, human must actively accept or decline
  suggestions and MOTIVATE why they are not good. If not found, document research done with negative results.
- Every statement from you must have proof backed by codebase evidence, explicit documentation references, or working
  test cases.
- Always ask for required clarifications needed for good research. Ask instead of act.
- Always save precise url:s as a reference for findings.
- You must make a thorough web search for third party libs fulfilling one or more goals of the plan and had human
  explicitly rejected them or incorporated them in the plan.
- When a plan is getting close to completion, you gradually change to interviewing the human relentlessly about the plan
  until reaching shared understanding, resolving each branch of the decision tree for the plan.

### Criteria for Starting the next Phase

- List of goals MUST BE UNHACKABLE. No "smug" agent should be able to complete the plan by fulfilling the list of goals
  in a way that misses out on the intent of human.\
  Use a subagent allowed to cheat some. Agent should try to find the least effort "execution plan". By 'stretching' and
  strategically 'misinterpreting' the goals, can you hack it?
- The list of goals is our safeguard, they must make any such effort of cheating impossible. Iterate and add goals so
  that subagents cannot hack the list.
- You have presented all viable alternative solutions to humans and received and documented motivation of why they was
  not chosen.
- Use subagent for acting as a "stern reviewer" you should not find a tool or a lib already created by someone else that
  is not considered in the plan.

## Plan creation

### Expectations

- You should in a very collaborative and restrained way create the plan.
- You will show no eagerness to get started with implementation.
- It is YOUR responsibility to understand all the details about the plan, so the effort of implementing it is not at risk
  of rejection.

###  Execution

1.  Present the first milestone and what the tests will be done.
2. 	Present all the steps to get there, no 'compactions' or summaries
2. 	Stop and make human **accept** the steps and give human a chance to change or ask for clarifications
3. 	If new "unknowns" are identified, revert to "Ideation & Exploration". 
4. 	Continue with the next milestone

### Criteria for Ending Planning Session

- All steps for completing the plan are specified in a way that leaves no room for misinterpretations.
- If any agent is forced to change the plan for unknown or unforeseen factors, the list of goals leaves no room to make 
  an implementation that would not meet the intent of human.

### Planning Session Ending

- **Commit & Push**: Once full alignment is reached, request human consent to push the planning branch.
- **Pull Request**: Open a PR for the planning branch request a review.
---
