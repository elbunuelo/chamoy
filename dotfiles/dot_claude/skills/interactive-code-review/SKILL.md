---
name: interactive-code-review
description: Interactive code review of branch changes with side-by-side diffs. Use when reviewing a feature branch, PR, or set of changes interactively with the user. Analyzes branch, proposes review order, walks through files with Edit-tool diffs and inline commentary.
---

# Interactive Code Review

Walk through branch changes file-by-file using the Edit tool to produce side-by-side diffs with inline commentary.

## Constraints

- **One file per response** — after each file, use the `question` tool to present next-step choices and **stop generating**. Do not batch files. Do not continue without a response.
- **All files use Edit-tool diffs** — modified, new, configs, migrations, specs. No read-and-comment reviews.
- **Restore with branch name** — never `git checkout HEAD -- <file>`. HEAD is contaminated after checking out base versions. Always use the stored branch name.
- **Commentary is factual during review** — no "this is good/bad", no suggestions. All opinions/judgements saved for Overall Assessment.
- **Validate assumptions** — never hypothesize that something is "probably handled elsewhere." Search the changeset to confirm. If a method omits logic (e.g., positioning, cleanup), find where it's actually done and cite file:line. Unvalidated claims erode review trust.
- **TodoWrite is phase-level** — one item per phase + gate items between phases. Per-file progress goes in response text (e.g., "2/4 files in Phase 3 done").
- **Feature files only** — if `git log --oneline --no-merges <base>..<branch> -- <file>` is empty, skip it (inherited noise).
- **Skip `db/structure.sql`** — auto-generated schema dump; no manual review needed. Verify migration-level changes are correct instead.
- **Always restore files** after reviewing, even if user interrupts or skips ahead.

## Phase 1: Branch Analysis

Delegate to a sub-agent to keep main context lean.

1. **Capture branch ref**: `git rev-parse --abbrev-ref HEAD`
2. **Determine base branch** — default `master`; ask user if unclear
3. **Delegate analysis** — Task tool with `subagent_type: "explore"`:

   > Analyze branch `<branch>` against base `<base>` for code review planning.
   >
   > 1. List non-merge commits: `git log --oneline --no-merges --format="%h %an: %s" <base>..<branch>`
   > 2. Identify the first feature commit hash
   > 3. Get feature-touched files (non-merge only): `git diff --name-only --diff-filter=AM <first-commit>^..<branch>`
   > 4. Get deleted files: `git diff --diff-filter=D --name-only <first-commit>^..<branch>`
   > 5. For ambiguous files, verify with: `git log --oneline --no-merges <base>..<branch> -- <file>` — if empty, exclude
   > 6. Group into review phases with dependency ordering:
   >    - Entry points / wiring first
   >    - Core logic (top-down, with specs alongside their implementation files)
   >    - Helpers / utilities
   >    - Tangential / cleanup last
   >    NOTE: Do NOT group specs into a separate phase. Place each spec file immediately after its corresponding implementation file within the same phase. Specs provide valuable insight into the implementation's behavior and edge cases.
   >
   > Return ONLY:
   > ```
   > Phase 1: <label>
   > - path/to/file.rb [NEW|MODIFIED|DELETED]
   >
   > Phase 2: <label>
   > - ...
   > ```
   > Nothing else.

4. **Look up PR** — check if a PR exists for the branch and cache the node ID for marking files as viewed:
   ```bash
   PR_NUMBER=$(gh pr list --head <branch> --json number --jq '.[0].number')
   if [ -n "$PR_NUMBER" ]; then
     PR_NODE_ID=$(gh api repos/{owner}/{repo}/pulls/$PR_NUMBER --jq '.node_id')
   fi
   ```
   Store `PR_NODE_ID` in the review plan. REST API has no "mark as viewed" — must use GraphQL with the node ID (not PR number).
5. **Exclude already-viewed files** — if `PR_NUMBER` was found, query for files already marked as viewed:
   ```bash
   gh api graphql -f query='
   query($owner: String!, $repo: String!, $number: Int!) {
     repository(owner: $owner, name: $repo) {
       pullRequest(number: $number) {
         files(first: 100) {
           nodes {
             path
             viewerViewedState
           }
         }
       }
     }
   }' -f owner='{owner}' -f repo='{repo}' -F number=$PR_NUMBER --jq '.data.repository.pullRequest.files.nodes[] | select(.viewerViewedState == "VIEWED") | .path'
   ```
   Remove these paths from the sub-agent's phase groupings before writing the plan. If all files in a phase were already viewed, skip that phase entirely and mark it completed in TodoWrite.
6. **Write plan** to `.claude/review-plan.md` (branch name, base branch, phase groupings, PR node ID if found, list of excluded viewed files). Read it back when recalling phase contents.
7. **Present plan to user** — note how many files were excluded as already viewed (e.g., "3 files already viewed, excluded from review"). **Stop and wait for approval** before proceeding.
8. **Create TodoWrite checklist** — one item per phase + gate items between phases. Phases with all files already viewed start as completed.

## Phase 2: Per-File Review

### Modified files

1. Explain what the file does and how it relates to other changed files
2. Check out base version: `git checkout <base-branch> -- <file>`
3. **Read** the file
4. **Edit** in logical chunks — one conceptual change per edit. Before each edit, describe:
   - What the change does
   - Security surface (auth checks, data scoping, input handling)
   - Edge cases or invariants
   - Interactions with other files in the changeset
5. **Pause after each chunk** — use the `question` tool after each Edit chunk to let the user ask questions about that specific chunk before moving to the next. Options: "Next chunk", "Earmark for later" (see Earmarking below), plus custom input via the `custom` flag. Only proceed to the next chunk after user responds. This applies to large files (>80 lines) with multiple logical chunks. **After answering a question or fulfilling a request (earmark, comment, etc.), re-present the same choices** — do not auto-advance to the next chunk.
6. Restore: `git checkout <branch-name> -- <file>`

### New files

1. Explain what the file does and how it relates to other changed files
2. **Write** an empty file at the path
3. **Read** the empty file
4. **Edit** branch content in logical chunks with factual callouts (same as modified files, including per-chunk pause)
5. Restore: `git checkout <branch-name> -- <file>`

### Spec/test files

Spec files are reviewed alongside their implementation (in the same phase, immediately after). When presenting test chunks:
- Explain **what each test/example verifies** — the behavior, edge case, or invariant being tested
- Note any **test setup** that reveals assumptions about the implementation (e.g., factory traits, stubs, mocks)
- Highlight **coverage gaps** — important behaviors from the implementation that lack test coverage
- Call out tests that validate **security boundaries** (auth, scoping, permissions)

### Deleted files

- Note the deletion, explain what the file contained and why it's being removed
- Check if anything still references it

### Existing PR comments

Before reviewing each file, check for existing review comments on that file:
```bash
gh api repos/{owner}/{repo}/pulls/$PR_NUMBER/comments --jq '.[] | select(.path == "path/to/file.rb") | "L\(.line) @\(.user.login): \(.body)"'
```
If comments exist:
1. Show them to the user before starting the Edit-tool diff (e.g., "Existing comments on this file: ...")
2. When performing Edit-tool diffs, include relevant PR discussion as comments in the chunk that contains the discussed line. Format: `# @author: comment text` placed on the line the discussion refers to. This embeds prior review context directly into the diff.

### Earmarking topics for later review

When the user asks to earmark a pattern, concept, or question for later review:
1. Create a markdown file in `$DOCS_DIR/learning/` (where `DOCS_DIR="$HOME/Projects/claude/projects/$(basename "$PWD")"` — create directory if needed)
2. Include: context (file, PR, pattern), code example, questions to explore
3. Filename: kebab-case summary (e.g., `tap-pattern-review.md`)

### After each file

- Note progress in response text
- If last file in phase, mark the phase TodoWrite item as completed
- **Mark as viewed gate** (only when `PR_NODE_ID` exists):
  - **Use the `question` tool** to ask: "Mark this file as viewed on GitHub?"
    - Options: `"Yes"`, `"No"`. Enable `custom: true` for free-text questions.
    - If user picks "Yes", run the mark-as-viewed mutation below.
    - If user types a question, answer it, then re-present the same yes/no choices.
  - **Stop generating. Wait for user response.**
- **Continue gate** — after the mark-as-viewed gate (or immediately if no `PR_NODE_ID`):
  - **Use the `question` tool** to present next-step choices. Enable `custom: true`.
    - `"Continue"` — proceed to next file
    - At phase boundaries, adjust wording (e.g., "Phase N complete — continue to Phase N+1?").
  - If user types a question, answer it, then re-present the same choices.
  - **Stop generating. Wait for user response.**
- **Mark file as viewed** mutation (used when user picks "Yes" in the mark-as-viewed gate):
  ```bash
  gh api graphql -f query='
  mutation($pullRequestId: ID!, $path: String!) {
    markFileAsViewed(input: {pullRequestId: $pullRequestId, path: $path}) {
      pullRequest { id }
    }
  }' -f pullRequestId="$PR_NODE_ID" -f path="path/to/reviewed-file.rb"
  ```

### Pending Review Comments

When a PR exists, create a **pending review** at the start and accumulate comments into it. Only submit at the end.

- **Create pending review with first comment** (REST API — `gh` doesn't support `PENDING` event via CLI flags):
  ```bash
  COMMIT_ID=$(git rev-parse <branch>)
  curl -s -X POST \
    -H "Authorization: token $(gh auth token)" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/{owner}/{repo}/pulls/$PR_NUMBER/reviews" \
    -d '{
      "commit_id": "'$COMMIT_ID'",
      "body": "",
      "comments": [
        {"path": "file.rb", "line": 10, "body": "Comment text"}
      ]
    }'
  ```
  Store the returned review `id` as `REVIEW_ID`.

- **Add subsequent comments to pending review** — use single-comment endpoint (not review endpoint):
  ```bash
  curl -s -X POST \
    -H "Authorization: token $(gh auth token)" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/{owner}/{repo}/pulls/$PR_NUMBER/comments" \
    -d '{
      "commit_id": "'$COMMIT_ID'",
      "path": "file.rb",
      "line": 15,
      "body": "Another comment"
    }'
  ```
  NOTE: These become standalone comments (not part of the pending review batch). GitHub API limitation — only the initial `POST /reviews` can batch comments into a pending review. Subsequent comments via `POST /comments` are published immediately.

  Alternative: collect all comments during the review, then create the pending review with all comments at the end via a single `POST /reviews` call. This keeps all comments in one reviewable batch.

## Phase 3: Overall Assessment

After all files reviewed:

- **Summary**: What the change does as a whole
- **Cross-cutting concerns**: Security, performance, test coverage gaps
- **Bugs & design issues**: Potential bugs, edge cases, questionable decisions
- **Risks**: Items needing follow-up or further testing
- **Quality assessment**: Overall readiness for merge
- **Ask user** whether to submit the pending review — use the `question` tool with options: `"Approve"`, `"Request changes"`, `"Comment"`. Enable `custom: true`.
- **Ask for review message** — after user picks the event type, use the `question` tool to ask: "Review message? (leave empty to skip)". Enable `custom: true` so the user can type a message body. Options: `"Submit without message"`. If the user types text, use it as the review body; if they pick "Submit without message", use an empty body.
- **Submit** via:
  ```bash
  curl -s -X POST \
    -H "Authorization: token $(gh auth token)" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/{owner}/{repo}/pulls/$PR_NUMBER/reviews/$REVIEW_ID/events" \
    -d '{"event": "<APPROVE|REQUEST_CHANGES|COMMENT>", "body": "<user message or empty>"}'
  ```
