---
name: document-branch-behavior
description: Document the behavior implemented in the current branch. Analyzes branch diff (excluding master merge noise), Aha! records, and PR discussion to produce a concise behavior doc. Use when a feature branch is ready for documentation or after code review.
---

# Document Branch Behavior

Produce a behavior document for the current branch's feature work, written to `$DOCS_DIR/docs/` (where `DOCS_DIR="$HOME/Projects/claude/projects/$(basename "$PWD")"`).

**Announce:** "I'm using the document-branch-behavior skill to document this branch's feature."

## Workflow

### 1. Identify the branch and its merge base

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
MERGE_BASE=$(git merge-base master "$BRANCH")
```

### 2. Get the feature diff (excluding master merge noise)

Use the helper script to get only commits authored on this branch — not merge commits from master:

```bash
./.claude/skills/document-branch-behavior/scripts/branch_diff.sh
```

This outputs the combined diff of branch-only commits. Review the diff to understand what was built.

If the diff is large, prioritize:
1. New files (services, models, controllers, components)
2. Modified files with substantial logic changes
3. Test files (reveal intended behavior and edge cases)
4. Migration files (schema changes)
5. Config/permission changes

### 3. Gather context from Aha! record and PR

- **Aha! record**: Extract the record reference from the branch name (e.g., `a-12345-feature-name` → `A-12345`). Use the `aha_get_record` tool to read the feature description, requirements, and acceptance criteria.
- **PR discussion**: Find the PR for this branch using `gh pr list --head "$BRANCH" --json number,title,url --limit 1`. Then fetch PR comments via `gh api repos/{owner}/{repo}/pulls/{number}/comments` and review comments via `gh api repos/{owner}/{repo}/pulls/{number}/reviews`. Look for design decisions, reviewer feedback, and implementation notes.

### 4. Write the behavior document

Output file: `$DOCS_DIR/docs/{slug}.md`

Use the branch name (minus the record prefix) as the slug. Example: branch `a-17480-notebook-conversion` → `notebook-conversion.md`.

#### Document structure

```markdown
# {Feature Title}

## Overview

{2-4 sentences: what this feature does, why it exists, and the high-level approach.}

## Architecture

{Pipeline/flow diagram if applicable. Service responsibilities table. Key classes and their files with line references (`file_path:line_number`).}

## Key Implementation Details

{Sections per major concept. Include:
- Data transformations and mappings
- Scale factors, unit conversions
- State machines or flow control
- Integration points with existing systems}

## Permissions

{New permissions added, who gets them.}

## Feature Flags

{Table: flag name, purpose, where checked.}

## Error Handling

{How failures are caught, reported, recovered from.}

## Design Decisions & Known Considerations

{Captured from PR discussion and Aha! record comments. Include rationale. Cite PR number when sourced from review.}
```

**Omit sections that don't apply** — don't include empty Feature Flags or Permissions sections.

### 5. Verification

- [ ] Document covers ALL new/modified services, models, controllers, components
- [ ] File/line references are accurate (spot-check 3+)
- [ ] Design decisions cite their source (PR comment, Aha! record, code comment)
- [ ] No master-merge noise documented as feature behavior
- [ ] Slug matches branch name convention

## Filtering Heuristics

When the branch has merge commits from master, the raw `git diff master...HEAD` includes unrelated changes. The helper script handles this by:

1. Listing commits on the branch that are NOT merge commits (`--no-merges`)
2. Filtering to commits reachable from HEAD but not from the merge base
3. Producing a combined diff of only those commits

If a file appears in both branch commits and master merges, the script includes only the branch's version of changes to that file.

## Output Quality

- **Concise**: Aim for the density of a well-written RFC, not a tutorial
- **Code references**: Use `file_path:line_number` format for key locations
- **Tables over prose** for mappings, flags, permissions
- **Diagrams**: ASCII art for pipelines/flows when they clarify architecture
- **No fluff**: Skip "Introduction" or "Background" sections that restate the obvious
