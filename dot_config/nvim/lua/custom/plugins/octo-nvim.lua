--  configuration for Octo.nvim https://github.com/pwntester/octo.nvim
-- The plugin interacts with the github gh cli from nvim.

-- Will use the o prefix to interact with the plugin via keymaps
vim.keymap.set('n', '<leader>op', '<cmd>:Octo pr search review-requested:elbunuelo state:open<cr>', { desc = 'Search PRs awaiting review from me.' })
vim.keymap.set('n', '<leader>os', '<cmd>:Octo pr search is:open<cr>', { desc = 'Search open PRs' })
vim.keymap.set('n', '<leader>om', '<cmd>:Octo pr search author:elbunuelo<cr>', { desc = 'Search my PRs' })

vim.keymap.set('n', '<leader>oc', '<cmd>:Octo pr checkout<cr>', { desc = 'Check out currently selected PR.' })
vim.keymap.set('n', '<leader>ori', '<cmd>:Octo review<cr>', { desc = 'Review the currently selected PR.' })
vim.keymap.set('n', '<leader>orc', '<cmd>:Octo review comments<cr>', { desc = 'Reveiw pending comments in current review.' })
vim.keymap.set('n', '<leader>ov', '<cmd>:Octo pr changes<cr>', { desc = 'View changes in current pr' })
vim.keymap.set('n', '<leader>ors', '<cmd>:Octo review submit<cr>', { desc = 'Submit current review.' })

-- <space>ca adds a comment
-- <space>sa adds a suggestion

return {
  'pwntester/octo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('octo').setup {
      suppress_missing_scope = {
        projects_v2 = true,
      },
      mappings = {
        submit_win = {
          approve_review = { lhs = '<C-s>', desc = 'approve review' },
        },
      },
    }
  end,
}
