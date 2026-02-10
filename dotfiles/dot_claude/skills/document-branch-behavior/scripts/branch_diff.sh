#!/usr/bin/env bash
# Outputs the combined diff of branch-only commits, excluding master merge noise.
# Usage: ./branch_diff.sh [base_branch]
#   base_branch: defaults to "master"

set -euo pipefail

BASE="${1:-master}"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
MERGE_BASE="$(git merge-base "$BASE" HEAD)"

# Get commit SHAs authored on this branch (not merge commits from master)
BRANCH_COMMITS=$(git log --no-merges --format="%H" "$MERGE_BASE..HEAD")

if [ -z "$BRANCH_COMMITS" ]; then
  echo "No branch-specific commits found." >&2
  exit 0
fi

# Produce combined diff of only branch-authored commits against merge base
# This excludes any changes that came in via `git merge master`
git diff "$MERGE_BASE" HEAD -- $(
  # Files touched by branch-only commits (not merge commits)
  echo "$BRANCH_COMMITS" | xargs -I{} git diff-tree --no-commit-id --name-only -r {} | sort -u
)
