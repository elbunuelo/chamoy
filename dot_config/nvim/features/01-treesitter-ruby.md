# Feature: Treesitter Ruby Support

## Status: Done

## Priority: Critical

## Problem
Ruby and ERB are not included in the treesitter `ensure_installed` list. This means:
- No semantic syntax highlighting for Ruby files
- No treesitter textobjects (e.g., `vam` to select a method, `vic` to select a class)
- No smart indentation based on syntax tree
- Limited code folding capabilities

## Solution
Add `ruby`, `embedded_template` (for ERB), and `yaml` to the treesitter ensure_installed list in `init.lua`.

## Implementation

Edit `init.lua` and find the treesitter `ensure_installed` table. Add the missing parsers:

```lua
ensure_installed = {
  'ruby',
  'embedded_template',  -- for ERB files (not 'erb')
  'yaml',
  -- existing entries below
  'c', 'cpp', 'lua', 'python', 'tsx', 'typescript', 'vimdoc', 'vim', 'vue', 'css', 'javascript'
}
```

## Validation
1. Open Neovim
2. Run `:TSInstall ruby erb yaml` (or let auto-install handle it)
3. Open a `.rb` file
4. Run `:InspectTree` to confirm treesitter is parsing the file
5. Test textobjects: position cursor inside a method and try `vam` (select around method)

## Dependencies
- nvim-treesitter (already installed)

## Files Modified
- `init.lua`
