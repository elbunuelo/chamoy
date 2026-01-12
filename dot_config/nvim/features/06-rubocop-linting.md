# Feature: Real-time Rubocop Linting

## Status: Pending

## Priority: Medium

## Problem
Rubocop is only running on save for formatting. You don't get real-time diagnostic feedback (warnings, style violations) as you type.

## Solution
Configure `none-ls.nvim` (null-ls successor) to provide Rubocop diagnostics.

## Implementation

Locate and modify the none-ls plugin configuration. Find or create the none-ls setup file:

```lua
return {
  'nvimtools/none-ls.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  ft = { 'ruby', 'eruby' },
  config = function()
    local null_ls = require('null-ls')
    null_ls.setup({
      sources = {
        null_ls.builtins.diagnostics.rubocop.with({
          command = 'bundle',
          args = vim.list_extend({ 'exec', 'rubocop' }, null_ls.builtins.diagnostics.rubocop._opts.args),
        }),
      },
    })
  end,
}
```

## Alternative: Use ruby_lsp diagnostics
If you prefer not to add none-ls, ensure ruby_lsp is providing diagnostics. Check your LSP config in `init.lua`:

```lua
ruby_lsp = {
  init_options = {
    enabledFeatures = {
      diagnostics = true,
    },
  },
},
```

## Validation
1. Open Neovim
2. Run `:Lazy sync` to install/update plugins
3. Open a Ruby file with intentional style violations
4. Check for diagnostic signs in the gutter (warnings, errors)
5. Run `:lua vim.diagnostic.open_float()` to see diagnostic details
6. Verify diagnostics update as you type (or on save)

## Dependencies
- none-ls.nvim (already installed but minimally configured)
- Rubocop in your project

## Files Modified
- Existing none-ls plugin configuration
