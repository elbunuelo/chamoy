# Feature: Bundler Integration

## Status: Pending

## Priority: Low

## Problem
No Gemfile navigation or bundle commands from within Neovim.

## Solution
Install `vim-bundler` for Gemfile support and bundle commands.

## Implementation

Create `lua/custom/plugins/bundler.lua`:

```lua
return {
  'tpope/vim-bundler',
  ft = { 'ruby', 'eruby' },
  dependencies = {
    'tpope/vim-projectionist',
  },
}
```

## Validation
1. Open Neovim
2. Run `:Lazy sync` to install the plugin
3. Open a Ruby project with a Gemfile
4. Run `:Bopen` to open the Gemfile
5. Position cursor on a gem name and press `gf` to navigate to the gem source
6. Run `:Bundle` to run bundle install

## Key Commands
| Command | Description |
|---------|-------------|
| `:Bundle` | Run bundle install |
| `:Bopen [gem]` | Open Gemfile or specific gem |
| `gf` | Go to gem source (on gem name in Gemfile) |

## Dependencies
- vim-projectionist (optional)

## Files Created
- `lua/custom/plugins/bundler.lua`
