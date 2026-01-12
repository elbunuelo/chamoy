# Feature: Ruby Debugging Support

## Status: Pending

## Priority: Medium

## Problem
DAP (Debug Adapter Protocol) is configured only for JavaScript/TypeScript. Cannot set breakpoints or step through Ruby code.

## Solution
Add `nvim-dap-ruby` for Ruby debugging support.

## Implementation

Create `lua/custom/plugins/dap-ruby.lua`:

```lua
return {
  'suketa/nvim-dap-ruby',
  dependencies = { 'mfussenegger/nvim-dap' },
  ft = 'ruby',
  config = function()
    require('dap-ruby').setup()
  end,
}
```

## Project Setup
Add the `debug` gem to your Gemfile:

```ruby
group :development, :test do
  gem 'debug', '>= 1.0.0'
end
```

Then run `bundle install`.

## Validation
1. Open Neovim
2. Run `:Lazy sync` to install the plugin
3. Ensure `debug` gem is installed in your project
4. Open a Ruby file
5. Set a breakpoint with `<leader>db` (or your DAP toggle breakpoint binding)
6. Start debugging with `<leader>dc` (continue/start)
7. Verify the debugger attaches and stops at breakpoints

## Key Bindings (existing DAP bindings)
| Binding | Description |
|---------|-------------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Toggle REPL |

## Dependencies
- nvim-dap (already installed)
- `debug` gem in Ruby project

## Files Created
- `lua/custom/plugins/dap-ruby.lua`
