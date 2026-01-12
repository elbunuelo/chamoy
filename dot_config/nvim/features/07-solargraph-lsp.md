# Feature: Solargraph LSP (Optional Enhancement)

## Status: Pending

## Priority: Low

## Problem
`ruby_lsp` is good but Solargraph provides different strengths:
- Better documentation lookup
- YARD documentation integration
- Different completion strategies

Some developers prefer running both LSPs for maximum coverage.

## Solution
Add Solargraph as an additional LSP server.

## Implementation

Edit `init.lua` and add Solargraph to the servers table:

```lua
local servers = {
  ruby_lsp = {},
  solargraph = {
    settings = {
      solargraph = {
        diagnostics = false, -- use rubocop via none-ls or ruby_lsp instead
        completion = true,
        hover = true,
        formatting = false, -- use rubocop via conform instead
        references = true,
        rename = true,
        symbols = true,
      },
    },
  },
  -- other servers...
}
```

## Project Setup
Add Solargraph to your project or install globally:

```bash
gem install solargraph
```

Or in Gemfile:
```ruby
group :development do
  gem 'solargraph'
end
```

Generate documentation cache:
```bash
solargraph bundle
```

## Validation
1. Open Neovim
2. Run `:Mason` and install `solargraph`
3. Open a Ruby file
4. Check `:LspInfo` to verify both `ruby_lsp` and `solargraph` are attached
5. Test hover documentation with `K`
6. Test completions by typing a method name

## Trade-offs
| Aspect | ruby_lsp | solargraph |
|--------|----------|------------|
| Speed | Faster | Slower startup |
| Rails support | Better | Good |
| Documentation | Basic | YARD integration |
| Diagnostics | Good | Good |
| Memory | Lower | Higher |

Consider using only `ruby_lsp` if you don't need the extra features.

## Dependencies
- Mason (already installed)
- Solargraph gem

## Files Modified
- `init.lua` (servers table)
