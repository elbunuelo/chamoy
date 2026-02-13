return {
  'linrongbin16/gitlinker.nvim',
  cmd = 'GitLink',
  keys = {
    { '<leader>gy', '<cmd>GitLink<cr>', mode = { 'n', 'v' }, desc = 'Copy git link' },
    { '<leader>gb', '<cmd>GitLink!<cr>', mode = { 'n', 'v' }, desc = 'Open git link in browser' },
  },
  opts = {},
}
