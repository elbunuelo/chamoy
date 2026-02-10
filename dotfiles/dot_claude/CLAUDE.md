## Style

- Unless specified in the project, start your conversations with "💀 Hey Nico, using default instructions"
- Telegraph; drop filler/grammar; min tokens
- Comments: only non-obvious *why*; prefer naming
- Files <500 LOC; split as needed
- Tight, high-signal docs
- Honest feedback always
- Push back if I suggest something that doesn't make sense
- Ask questions if something is not clear
- Ask questions one at a time

## Tools
- `fd` > find, `rg` > grep

## Conventions
- Mirror ~2 same-type files before creating new
- Check subtree AGENTS.md via `fd AGENTS.md`
- Never skip pre-commit hooks

## Auxiliary Files

Auxiliary/documentation files live **outside** the project repo, in a shared docs directory:

```
~/Projects/claude/projects/<project_name>/
```

`<project_name>` = last segment of the project's working directory (e.g., `/Users/me/Projects/aha-app` → `aha-app`).

**Resolve the docs dir at the start of every session:**
```bash
DOCS_DIR="$HOME/Projects/claude/projects/$(basename "$PWD")"
mkdir -p "$DOCS_DIR/features"
```

All auxiliary file references below are relative to `$DOCS_DIR`:
- **PROJECT.md**: Overview, features, stack, development commands
- **ARCHITECTURE.md**: System design, component relationships, data flow
- **CHANGELOG.md**: Version history and changes
- **LEARNINGS.md**: Non-obvious discoveries from implementation
- **APPROVALS.md**: Overseer verdicts
- **features/PRIORITIES.md**: Feature backlog with priority order
- **features/DEPENDENCIES.md**: Feature dependency tree
- **features/NNN-name.md**: Individual specs with status, requirements, e2e test references

**Never write these files to the project repo root.** Always use `$DOCS_DIR`.

## Workflow Agents

- Whenever an agent needs to get input from the user, bring it to the foreground.

### Implementation Flow
1. **architect**: Plan features before coding (handles both exploration and structured planning)
   - Vague ideas → proposes approaches first, then clarifies
   - Clear requirements → structured clarification, then design
   - Creates spec in feature file; user approves before dev
   - Invokes librarian for PRIORITIES.md & DEPENDENCIES.md updates
   - Receives escalations from dev for mid-implementation architectural issues
2. **dev**: Implement features from feature files
   - TDD: write failing test → implement → pass → refactor
   - Wires classes into entry point; runs tests + linter
   - When stuck: drops into playground mode (disposable scripts in `playground/`)
   - Escalates to architect when discovering design issues
   - Invokes librarian for doc updates on completion
3. **librarian**: Update documentation (all docs in `$DOCS_DIR`)
   - **After architect**: features/PRIORITIES.md, features/DEPENDENCIES.md
   - **After dev**: ARCHITECTURE.md, PROJECT.md, CHANGELOG.md, feature file (status→Done), LEARNINGS.md

### Sub-agent Escalation
- Sub-agents write important context for other sub-agents in the feature file.
- Sub-agents can't dispatch other sub-agents; return to parent with escalation request
- Pattern: sub-agent reports "user wants [agent] for [task]", parent dispatches target agent
- Never continue without escalating when user requests different agent
