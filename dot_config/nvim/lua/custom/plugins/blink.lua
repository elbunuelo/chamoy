-- https://cmp.saghen.dev/
return {
  'saghen/blink.cmp',
  dependencies = {
    {
      'L3MON4D3/LuaSnip',
      config = function()
        local luasnip = require 'luasnip'
        luasnip.config.setup {}
      end,
    },
  },
  version = '*',
  opts = {
    enabled = function()
      return not vim.tbl_contains({ 'markdown' }, vim.bo.filetype) and vim.bo.buftype ~= 'prompt' and vim.b.completion ~= false
    end,
    keymap = {
      preset = 'default',
      ['<C-n>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-k>'] = { 'select_prev', 'fallback' },
      ['<C-j>'] = { 'select_next', 'fallback' },
      ['<Tab>'] = { 'select_and_accept', 'fallback' },
    },
    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
    },
    snippets = { preset = 'luasnip' },
    sources = {
      default = { 'lsp', 'path', 'buffer' },
    },
  },
  opts_extend = { 'sources.default' },
}
