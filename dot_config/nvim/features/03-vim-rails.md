# Feature: Rails Integration

## Status: Pending

## Priority: High

## Problem
No Rails-specific navigation or commands. Missing:
- `:Emodel`, `:Econtroller`, `:Eview` navigation
- `:A` to jump to alternate file (model <-> test)
- `gf` support for partials (e.g., `render 'shared/header'`)
- `:Rake` and `:Rails` commands
- Projection-based navigation

## Solution
Install `vim-rails` for comprehensive Rails integration.

## Implementation

Create `lua/custom/plugins/rails.lua`:

```lua
return {
  'tpope/vim-rails',
  ft = { 'ruby', 'eruby', 'haml', 'slim' },
  dependencies = {
    'tpope/vim-projectionist', -- for custom projections
  },
}
```

## Validation
1. Open Neovim
2. Run `:Lazy sync` to install the plugin
3. Open a Rails project
4. Run `:Emodel User` to open the User model
5. Run `:A` to jump to the associated test file
6. In a view, position cursor on a partial name and press `gf`

## Key Commands
| Command | Description |
|---------|-------------|
| `:Emodel [name]` | Edit model |
| `:Econtroller [name]` | Edit controller |
| `:Eview [name]` | Edit view |
| `:A` | Alternate file (e.g., model <-> test) |
| `:R` | Related file |
| `:Rake` | Run rake tasks |
| `gf` | Go to file under cursor (partials, helpers) |

## Dependencies
- vim-projectionist (optional, for custom projections)

## Files Created
- `lua/custom/plugins/rails.lua`
