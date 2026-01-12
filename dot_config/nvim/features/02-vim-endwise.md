# Feature: Automatic End Block Insertion

## Status: Pending

## Priority: High

## Problem
When typing `def`, `do`, `class`, `module`, `if`, etc. in Ruby, you must manually type the closing `end`. This is tedious and error-prone.

## Solution
Install `vim-endwise` to automatically insert `end` after pressing Enter on lines that start blocks.

## Implementation

Create `lua/custom/plugins/endwise.lua`:

```lua
return {
  'tpope/vim-endwise',
  ft = { 'ruby', 'eruby', 'lua', 'elixir', 'crystal' },
}
```

## Validation
1. Open Neovim
2. Run `:Lazy sync` to install the plugin
3. Open or create a `.rb` file
4. Type `def foo` and press Enter
5. Verify that `end` is automatically inserted below

## Dependencies
- None (standalone plugin)

## Files Created
- `lua/custom/plugins/endwise.lua`
