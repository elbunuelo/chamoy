# Chamoy-managed dotfiles

The following files and directories are managed by the `chamoy` script and **copied from `~/Projects/chamoy`** to their target locations. Any direct edits will be **overwritten** on the next `chamoy` run.

**NEVER edit these files in-place.** Always make changes in `~/Projects/chamoy` instead.

| Source (~/Projects/chamoy/)              | Target                              |
|------------------------------------------|-------------------------------------|
| `dot_config/` (dirs)                     | `$XDG_CONFIG_HOME/`                 |
| `dot_config/starship.toml`               | `$XDG_CONFIG_HOME/starship.toml`    |
| `dot_local/` (dirs)                      | `~/.local/`                         |
| `dotfiles/dot_tmux.conf`                 | `~/.tmux.conf`                      |
| `dotfiles/dot_tmuxlinerc`                | `~/.tmuxlinerc`                     |
| `dotfiles/dot_chela`                     | `~/.chela`                          |
| `dotfiles/dot_tool-versions`             | `~/.tool-versions`                |
| `dotfiles/dot_claude/` (dirs)            | `~/.claude/`                        |
| `dotfiles/dot_claude/CLAUDE.md`          | `~/.claude/CLAUDE.md`               |
| `Library/KeyBindings/DefaultKeyBinding.dict` | `~/Library/KeyBindings/` (macOS) |
| `CLAUDE.md`                              | `~/CHAMOY_CLAUDE.md`                       |
