# Learnings

Non-obvious gotchas discovered while implementing Neovim features.

---

## Treesitter ERB parser is named `embedded_template`

**Context:** Adding treesitter support for Ruby/ERB files.

**Gotcha:** The treesitter parser for ERB files is not called `erb` — it's called `embedded_template`. Running `TSInstallSync erb` fails with "Parser not available for language 'erb'".

**Solution:** Use `embedded_template` in your `ensure_installed` list:

```lua
ensure_installed = { 'ruby', 'embedded_template', 'yaml', ... }
```

**How to discover available parsers:** Run this in Neovim to search for parser names:

```vim
:lua for k,v in pairs(require('nvim-treesitter.parsers').get_parser_configs()) do if k:match('pattern') then print(k) end end
```
