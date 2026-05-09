---
name: update-config
description: Use when creating, editing, or deleting OpenCode agent configuration, skills, prompts, plugins, MCP settings, or instruction files for Nico
---

# Update Config

## Overview

Nico manages OpenCode configuration through Chamoy. Do not write live OpenCode config under `~/.config/opencode`; write the source config under `~/Projects/chamoy/dot_config/opencode`, then ask whether to run `chamoy` to apply it.

## When To Use

Use this skill before changing OpenCode agent configuration, including:

- Skills, prompts, plugins, agents, MCP settings, or `opencode.json`
- Instructions about how agents should behave
- Any request phrased as updating your config, agent config, OpenCode config, or self-configuration

## Rule

Always edit Chamoy source files:

| Config type | Write here |
|---|---|
| OpenCode config | `~/Projects/chamoy/dot_config/opencode` |
| OpenCode skills | `~/Projects/chamoy/dot_config/opencode/skills` |
| OpenCode superpower skills | `~/Projects/chamoy/dot_config/opencode/skills/superpowers` |

Do not edit `~/.config/opencode` for persistent config changes unless Nico explicitly asks for a live-only patch.

## Workflow

1. Locate the matching Chamoy file or directory under `~/Projects/chamoy/dot_config/opencode`.
2. Make the smallest correct change there.
3. Verify the changed file exists in Chamoy, not just in `~/.config/opencode`.
4. Before final handoff, ask: `Run chamoy to apply the current configuration?`

If the user says yes, run `chamoy` from the shell and report the result.

## Example

User: "Write an OpenCode skill called foo."

Correct target:

```text
~/Projects/chamoy/dot_config/opencode/skills/superpowers/foo/SKILL.md
```

Final handoff must include:

```text
Run chamoy to apply the current configuration?
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Writing to `~/.config/opencode` because it is the standard path | Write to Chamoy source instead |
| Creating symlinks or moving config into a dotfiles repo | Chamoy already manages this; only edit its source files |
| Forgetting the apply step | Always ask whether to run `chamoy` after updating config |
| Asking about `chamoy` before making the requested edit | Ask after the config change is complete |

## Red Flags

- "I'll just edit live config this once"
- "Future sessions will pick it up automatically"
- "The user did not mention Chamoy this time"
- "Running or offering `chamoy` is unnecessary"
- "I should migrate or symlink config into dotfiles"

All of these mean: stop and use the Chamoy path.
