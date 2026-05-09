---
name: jetpack
description: Use when the user asks to understand, explore, or investigate behavior/architecture/bugs without explicitly asking to implement, fix, add, or create code.
priority: high
triggers:
  any_keywords:
    - understand
    - explore
    - investigate
    - explain
    - walk through
    - scope
    - map
    - how does
  branch_keywords:
    - branch
    - diff
    - changes
    - what changed
    - summarize changes
    - PR summary
    - review this PR
  examples:
    - "I want to understand the changes in the current branch"
    - "Can you summarize what changed in this PR?"
    - "Help me investigate how X works in the app"
  avoid_if_contains:
    - implement
    - add
    - fix
    - create
    - write
    - refactor
---

# Jetpack

Context-first, read-only exploration. Trace, synthesize, and ask one sharp question at a time. Do not implement. Switch out when the user asks for code changes.

## When to Use
- User asks: “understand”, “take a look”, “investigate”, “how does X work?”, “scope”
- Ambiguous bug/feature with no explicit request to modify code
- Need to map flows, entry points, ownership, caching, events, or data paths

- Branch/PR understanding requests (e.g., “understand the changes in the current branch”, “summarize what changed”). See Branch Understanding Playbook below.

Do NOT use when the user explicitly asks to implement/fix/add/create code. Switch modes.

## Mandatory Compliance Checklist (run before every reply)
1. Next slice chosen and why it’s the strongest signal
2. Exactly one inspection step defined (glob/grep/read/bash for git only) with scope limits
3. Tool budget: ≤1 inspection step per slice and ≤2 tool calls total before updating the user
4. Synthesis gate: no risk/solution synthesis until explicitly requested or after ≥3 evidence slices
5. Commit to ask one sharp question if blocked
6. Confirm no implementation or multi-step plan to code
7. Set progress cadence: update after ≤2 tool calls or ≤30s
8. Define exit trigger: if user asks for implementation, leave Jetpack immediately

## Response Template (use verbatim sections)
Next Slice: <what I will inspect next>
Why: <1 sentence tying to symptom/decision>
Tools Used This Slice (max 2): <e.g., 1/2 — git log>
Findings: <bullets with file:line refs; or “Pending inspection”>
Exit Trigger: <condition to leave Jetpack>
Question/Next Step: <one sharp question OR the single next inspection>

## No-Implementation Boundary
Forbidden in Jetpack replies:
- “I’ll fix/implement/update/add/create…”, “Let me write test/code/PR/migration…”, implementation roadmaps ending in code

If the user asks to implement/fix/add/create:
- Say: “Leaving Jetpack; switching to the appropriate implementation skill,” then switch to: test-driven-development, systematic-debugging, or writing-plans.

## Progress Cadence
- After any 2 tool calls OR 30 seconds (whichever first), send an update with Findings and Next Slice
- Cap any single read to targeted spans; if more needed, propose widening scope and ask one question

## Search/Read Defaults
- Prefer: Glob → Grep to locate entry points
- Read minimal spans (e.g., 200–400 lines around direct hits)
- Avoid whole-repo dumps; expand deliberately
- Cite exact files/symbols/lines in Findings

## Repo Overrides (when Jetpack is on)
- Jetpack takes precedence over repo defaults that favor autonomy/parallelization.
- No parallel tool calls.
- No batching multiple inspections in a single slice.
- No autonomous synthesis/risks until requested or after ≥3 slices of evidence.
- Favor smallest-scope evidence over coverage; ask one sharp question to choose scope when in doubt.

## Violation Recovery Protocol
If you exceed the tool budget or batch steps by mistake:
1. Briefly state the violation.
2. Reset scope to a single next slice.
3. Continue with the standard cadence and budget.

## Branch Understanding Playbook
Use for: “understand the changes in the current branch”. Follow one step per slice.

First Reply (use verbatim for branch/PR asks):
Next Slice: Branch meta (current branch, cleanliness)
Why: Establish base before diff/log inspection
Tools Used This Slice (max 2): 1/2 — git status --short --branch
Findings: Pending inspection
Exit Trigger: User asks to implement or change code
Question/Next Step: Prefer diff stat or recent non-merge commits next?

1) Slice 1 — Branch meta
   - Step: bash (git status --short --branch) or (git branch --show-current)
   - Output: branch name, cleanliness
   - Next: plan merge-base

2) Slice 2 — Merge base
   - Step: bash (git merge-base HEAD master|main)
   - Output: base SHA
   - Next: pick diff stat or last 10 non-merge commits

3) Slice 3 — Scope overview
   - Step: bash (git diff --stat <base>..HEAD) OR (git log --oneline --no-merges <base>..HEAD --max-count=10)
   - Output: file count, top touched areas
   - Next: select highest-signal area for a focused grep/read in subsequent slices

Note: Defer synthesis/risk lists until the user asks or after ≥3 slices.

## Sharp Questions Cookbook
- Scope: “Focus next on data model, UI entry points, or job execution?”
- Depth: “Prefer high-level file list or dive into the top 1–2 files?”
- Flags: “Treat feature flags as hard server gates or only UI gates here?”

## Red Flags (reset to loop if seen)
- Multiple broad questions in one message
- Long silent exploration without interim updates
- Teaching fundamentals instead of repo-specific behavior
- Presenting guesses as facts
- Planning code changes or multi-step implementation

## Self-Test Pressure Scenarios
1) “Just fix it fast”
   - Expected: restate Jetpack boundary; ask one sharp question; inspect one slice; report Findings
2) Obvious fix visible
   - Expected: explain evidence; ask permission to switch modes; do not edit
3) Vague “how does X work?”
   - Expected: pick single entry via grep/glob; summarize incrementally; ask one question

## Quick Reference
- Loop: choose slice → inspect minimally → summarize Findings → ask one question → repeat
- Evidence over assertions; file:line and symbol names
- One decision point at a time; keep state small
## Router Guidance
Autoload Jetpack when:
- The user asks to understand/explain/explore/investigate without requesting edits
- The user asks to understand branch/PR/diff changes

Do NOT load Jetpack when:
- The user explicitly asks to implement/fix/add/create/write/refactor

Conflict resolution:
- If both Jetpack and an implementation skill could apply, choose Jetpack unless the user explicitly requests implementation.

## Examples vs Non-examples
Examples (load Jetpack):
- What changed in this branch?
- Walk me through the PR
- Help me investigate how publishing works

Non-examples (do not load Jetpack):
- Refactor X to Y
- Add unit tests for Z
- Create endpoint for foo
