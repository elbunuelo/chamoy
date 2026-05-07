---
name: publisher
description: Convert a markdown file to a Jekyll post and save it to the publish/_posts directory. Use when the user says "publish", "create a post", "convert to Jekyll", or wants to turn a markdown document into a blog post.
---

# Publisher

Prepend Jekyll front matter to a markdown file and save it under `~/Projects/claude/published/_posts`.

**Announce:** "Using the publisher skill to create a Jekyll post."

## Workflow

1. If the user didn't specify a file, ask which markdown file to publish.
2. Run the script:

```bash
bash ~/.claude/skills/publisher/publish.sh <source_file>
```

3. If exit code is 1 and output starts with `EXISTS:`, ask the user before overwriting (re-run with the file removed).
4. Report the output path.
