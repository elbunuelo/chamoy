vim.keymap.set({ 'n' }, '<leader>n', ':Neotree toggle<CR>', { desc = 'Toggle file tree' })
vim.keymap.set({ 'n' }, '<leader>m', ':Neotree reveal<CR>', { desc = 'Reveal file in tree' })

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  opts = {
    close_if_last_window = true,
    window = {
      mappings = {
        ['<C-x>'] = 'close_window',
      },
    },
    sources = {
      -- default sources
      'filesystem',
      'buffers',
      'git_status',
      -- user sources goes here
    },
  },
}
