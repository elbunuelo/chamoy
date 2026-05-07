#!/usr/bin/env bash
set -euo pipefail

SOURCE="${1:?Usage: publish.sh <source_file>}"
PROJECT_NAME="$(basename "$PWD")"
POSTS_DIR="$HOME/Projects/claude/published/_posts"
DATE="$(date +%Y-%m-%d)"

mkdir -p "$POSTS_DIR"

# Extract title from first heading; fall back to filename
TITLE="$(grep -m1 '^# ' "$SOURCE" | sed 's/^# //')"
if [ -z "$TITLE" ]; then
  TITLE="$(basename "$SOURCE" .md | tr '-_' '  ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')"
fi

SLUG="$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
OUTFILE="$POSTS_DIR/${DATE}-${SLUG}.md"

if [ -f "$OUTFILE" ]; then
  echo "EXISTS: $OUTFILE"
  exit 1
fi

{
  cat <<EOF
---
layout: post
title: "$TITLE"
date: $DATE
tags:
  - $PROJECT_NAME
---

EOF
  sed '0,/^# /{/^# /d;}' "$SOURCE"
} > "$OUTFILE"

echo "Published: $OUTFILE"
