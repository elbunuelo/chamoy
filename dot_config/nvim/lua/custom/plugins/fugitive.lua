return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gs', '<cmd>:Git<cr>', { silent = true, desc = 'Open git status' })
    vim.keymap.set('n', '<leader>gw', '<cmd>:Gwrite<cr>', { silent = true, desc = 'Stage current file' })
    vim.keymap.set('n', '<leader>gr', '<cmd>:Gread<cr>', { silent = true, desc = 'Checkout current file' })
    vim.keymap.set('n', '<leader>gc', '<cmd>:Git commit<cr>', { silent = true, desc = 'Commit staged files' })
    vim.keymap.set('n', '<leader>gB', '<cmd>:Git blame<cr>', { silent = true, desc = 'Open [G]it [B]lame for current file' })
    vim.keymap.set('n', '<leader>gd', '<cmd>:Git diff<cr>', { silent = true, desc = 'Diff current file' })
  end,
}
