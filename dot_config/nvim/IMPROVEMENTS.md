# Ruby Development Improvements for Neovim

## Current State Assessment

Your Neovim configuration is based on kickstart.nvim and is **well-suited for JavaScript/TypeScript development** but has **significant gaps for Ruby development**.

### What Works
- **Ruby LSP**: `ruby_lsp` is configured and provides basic LSP features
- **Code Formatting**: rubocop-daemon wrapper for fast formatting on save
- **Jbuilder**: Template support for JSON builders

### What's Missing
- No treesitter support for Ruby/ERB (no syntax highlighting, textobjects)
- No automatic `end` block insertion
- No Rails-specific navigation
- No Ruby test runner (RSpec/Minitest)
- No Ruby debugger
- No real-time linting (only format on save)
- No Gemfile/Bundler integration

## Feature Breakdown

Each feature is documented in the `features/` directory with implementation details and validation steps.

| # | Feature | Priority | Complexity | Status | File |
|---|---------|----------|------------|--------|------|
| 1 | Treesitter Ruby/ERB | Critical | Low | Done | `01-treesitter-ruby.md` |
| 2 | vim-endwise | High | Low | Pending | `02-vim-endwise.md` |
| 3 | vim-rails | High | Low | Pending | `03-vim-rails.md` |
| 4 | neotest-rspec | High | Medium | Pending | `04-neotest-rspec.md` |
| 5 | DAP Ruby Debugging | Medium | Medium | Pending | `05-dap-ruby.md` |
| 6 | Rubocop Linting | Medium | Medium | Pending | `06-rubocop-linting.md` |
| 7 | Solargraph LSP | Low | Low | Pending | `07-solargraph-lsp.md` |
| 8 | vim-bundler | Low | Low | Pending | `08-vim-bundler.md` |

## Recommended Implementation Order

### Phase 1: Essential (Do First)
1. **01-treesitter-ruby.md** - Enables proper syntax highlighting and textobjects
2. **02-vim-endwise.md** - Quality of life improvement for writing Ruby
3. **03-vim-rails.md** - Essential if you work with Rails projects

### Phase 2: Testing & Debugging
4. **04-neotest-rspec.md** - Run tests from within Neovim
5. **05-dap-ruby.md** - Step-through debugging for Ruby

### Phase 3: Polish
6. **06-rubocop-linting.md** - Real-time feedback on code style
7. **07-solargraph-lsp.md** - Optional, only if ruby_lsp isn't sufficient
8. **08-vim-bundler.md** - Nice to have for Gemfile navigation

## Files to Modify

| File | Changes |
|------|---------|
| `init.lua` | Add ruby/erb to treesitter, optionally add solargraph |
| `lua/custom/plugins/endwise.lua` | Create new file |
| `lua/custom/plugins/rails.lua` | Create new file |
| `lua/custom/plugins/neotest.lua` | Add neotest-rspec adapter |
| `lua/custom/plugins/dap-ruby.lua` | Create new file |
| `lua/custom/plugins/none-ls.lua` | Configure rubocop diagnostics |
| `lua/custom/plugins/bundler.lua` | Create new file |

## Expected Outcome

After implementing all features, your Ruby development experience will include:
- Semantic syntax highlighting with treesitter
- Smart textobjects (select method, class, block)
- Automatic `end` insertion
- Rails navigation (`:Emodel`, `:A`, `gf` for partials)
- Run RSpec tests with `<leader>tr`
- Debug Ruby with breakpoints
- Real-time Rubocop diagnostics
- Gemfile navigation

## Notes

- All features use lazy loading (`ft = 'ruby'`) to avoid slowing down Neovim startup
- Most plugins are from Tim Pope (tpope) - battle-tested and well-maintained
- ruby_lsp is actively developed by Shopify and is the recommended Ruby LSP
- Consider your actual workflow before adding all features - start with Phase 1

## Status Workflow

Each feature file includes a `Status` field that tracks implementation progress:

| Status | Description |
|--------|-------------|
| **Pending** | Feature has not been implemented yet |
| **Done** | Feature has been implemented and validated |

### Updating Status

When implementing a feature:
1. Follow the implementation steps in the feature file
2. Complete all validation steps to confirm the feature works
3. Change the `Status` field from `Pending` to `Done` in both:
   - The individual feature file (e.g., `features/01-treesitter-ruby.md`)
   - The feature table in this file (IMPROVEMENTS.md)

### Validation Requirements

Each feature includes a Validation section with specific steps to verify the implementation works correctly. A feature should only be marked as `Done` after all validation steps pass.
