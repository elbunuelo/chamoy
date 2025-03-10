return {
  'default-anton/llm-sidekick.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('llm-sidekick').setup {
      -- Model aliases configuration
      aliases = {
        pro = 'gemini-2.0-pro',
        flash = 'gemini-2.0-flash',
        sonnet = 'anthropic.claude-3-7-sonnet',
        deepseek = 'deepseek-chat',
        gpt4o = 'gpt-4o-2024-11-20',
        high_o3_mini = 'o3-mini-high',
        low_o3_mini = 'o3-mini-low',
        medium_o3_mini = 'o3-mini-medium',
      },
      yolo_mode = {
        file_operations = false, -- Automatically accept file operations
        terminal_commands = false, -- Automatically accept terminal commands
      },
      default = 'sonnet',
    }

    vim.keymap.set('n', '<leader>la', '<cmd>Chat vsplit<CR>', { noremap = true, desc = 'Chat without context' })
    vim.keymap.set('n', '<leader>lc', '<cmd>Chat vsplit %<CR>', { noremap = true, desc = 'Chat with the current buffer' })
    vim.keymap.set('v', '<leader>lc', '<cmd>Chat vsplit<CR>', { noremap = true, desc = 'Chat with selected code' })
    vim.keymap.set('n', '<leader>ld', '<cmd>Chat vsplit %:h<CR>', { noremap = true, desc = 'Chat with the current directory' })

    -- Only set <C-a> mappings if not in telescope buffer
    local function set_add_keymap()
      local opts = { noremap = true, silent = true }
      -- Check if current buffer is not a telescope prompt
      if vim.bo.filetype ~= 'TelescopePrompt' and vim.bo.filetype ~= 'oil' then
        vim.keymap.set('n', '<C-a>', ':Add<CR>', vim.tbl_extend('force', opts, { desc = 'Add context to LLM' }))
        vim.keymap.set('v', '<C-a>', ':Add<CR>', vim.tbl_extend('force', opts, { desc = 'Add selected context to LLM' }))
      end
    end

    -- Set up an autocmd to run when entering buffers
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
      callback = function()
        set_add_keymap()
      end,
    })
  end,
}
