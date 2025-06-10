-- Plugin: chamoy.lua
-- Description: Creates a Neovim command to execute chamoy and adds keybinding

-- Create the Chamoy command that executes !chamoy
vim.api.nvim_create_user_command('Chamoy', function()
  vim.cmd('!chamoy')
end, { desc = 'Execute chamoy command' })

-- Add normal mode keybinding for <leader>C
vim.keymap.set('n', '<leader>C', ':Chamoy<CR>', { desc = 'Execute chamoy command', silent = true })
