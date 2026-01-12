# Feature: RSpec Test Runner Integration

## Status: Pending

## Priority: High

## Problem
Neotest is configured with Jest but has no Ruby test adapter. Cannot run RSpec or Minitest from Neovim.

## Solution
Add `neotest-rspec` adapter to the existing neotest configuration.

## Implementation

Locate and modify the neotest plugin configuration. Find the file containing neotest setup (likely in `lua/custom/plugins/`) and add the RSpec adapter:

```lua
return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-neotest/neotest-jest',
    'olimorris/neotest-rspec', -- Add this
  },
  config = function()
    require('neotest').setup({
      adapters = {
        require('neotest-jest')({
          -- existing jest config
        }),
        require('neotest-rspec')({
          rspec_cmd = function()
            return vim.tbl_flatten({
              'bundle',
              'exec',
              'rspec',
            })
          end,
        }),
      },
    })
  end,
}
```

## Validation
1. Open Neovim
2. Run `:Lazy sync` to install neotest-rspec
3. Open an RSpec file (`*_spec.rb`)
4. Run `<leader>tr` to run the nearest test
5. Run `<leader>tt` to run the current file
6. Run `<leader>ts` to see the test summary panel

## Key Bindings (existing)
| Binding | Description |
|---------|-------------|
| `<leader>tt` | Run file |
| `<leader>tr` | Run nearest test |
| `<leader>tl` | Run last test |
| `<leader>ts` | Toggle summary |
| `<leader>to` | Show output |

## Dependencies
- neotest (already installed)
- RSpec in your project (`bundle exec rspec` must work)

## Files Modified
- Existing neotest plugin configuration file
