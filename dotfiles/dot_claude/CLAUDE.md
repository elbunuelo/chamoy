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
Projects use these documentation files:
- **PROJECT.md**: Overview, features, stack, development commands
- **ARCHITECTURE.md**: System design, component relationships, data flow
- **CHANGELOG.md**: Version history and changes
- **LEARNINGS.md**: Non-obvious discoveries from implementation
- **PRIORITIES.md**: Feature backlog with priority order (in `features/`)
- **DEPENDENCIES.md**: Feature dependency tree (in `features/`)
- **Feature files**: Individual specs in `features/` directory with status, requirements, e2e test references

## Workflow Agents

### Implementation Flow
0. **brainstormer**: Discuss new features, ideas, or improvements (optional)
   - Explore problem space before committing to solution
   - Capture opportunities, pain points, user needs
   - Output: rough feature concepts for architect to spec
   - Skip for existing/well-defined features
1. **architect**: Plan complex features before coding
   - Analyze codebase, design approach, identify files to modify
   - Creates spec in feature file; user approves before dev
   - Invokes librarian for PRIORITIES.md & DEPENDENCIES.md updates
   - Invokes tinkerer to de-risk uncertain approaches
   - Receives escalations from dev for mid-implementation architectural issues
2. **dev**: Implement features from feature files
   - TDD: write failing test → implement → pass → refactor
   - Follows Definition of Done; wires classes into entry point
   - Runs tests + linter before completing
   - Escalates to tinkerer when stuck (debugging, unfamiliar APIs)
   - Escalates to architect when discovering design issues
3. **code-reviewer**: After dev, verify quality
   - Classes wired into production entry point
   - No commented-out requires
   - E2E test covers feature path
   - Verify feature file has e2e test reference
4. **librarian**: Invoked at two points:
   - **After architect**: PRIORITIES.md, DEPENDENCIES.md
   - **After code-reviewer**: ARCHITECTURE.md, PROJECT.md, CHANGELOG.md, feature file (status→Done), LEARNINGS.md
5. **overseer**: After librarian, verify before commit
   - Runs unit tests and e2e tests
   - PRIORITIES.md: completed features struck through
   - DEPENDENCIES.md: completed features removed from tree
   - Feature file status matches implementation state
   - Documented patterns applied correctly
6. **tinkerer**: After overseer, identify automation opportunities
   - Reviews completed work for patterns worth scripting
   - Creates playground scripts to aid future development
   - Prototypes solutions when agents are stuck (debugging, unfamiliar APIs)
   - Hands off non-obvious learnings to librarian
7. **committer**: After tinkerer, commit changes

### Workflow Discipline
- Multi-step workflows need TodoWrite tracking; memory leads to skipped steps
- Pattern: create todo list for workflow steps immediately; mark in_progress/completed in real-time

### Sub-agent Escalation
- Sub-agents write important context for other sub-agents in the feature file.
- Sub-agents can't dispatch other sub-agents; return to parent with escalation request
- Pattern: sub-agent reports "user wants [agent] for [task]", parent dispatches target agent
- Never continue without escalating when user requests different agent
