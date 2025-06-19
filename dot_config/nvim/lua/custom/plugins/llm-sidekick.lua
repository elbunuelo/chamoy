return {
  'default-anton/llm-sidekick.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('llm-sidekick').setup {
      aliases = {
        chatgpt = 'gpt-4.1',
        mini = 'gpt-4.1-mini',
        flash = 'gemini-2.0-flash',
        pro = 'gemini-2.5-pro',
        sonnet = 'anthropic.claude-3-7-sonnet',
      },
      yolo_mode = {
        file_operations = false, -- Automatically accept file operations
        terminal_commands = false, -- Automatically accept terminal commands
        auto_commit_changes = true, -- Enable auto-commit
      },
      auto_commit_model = 'gpt-4.1-mini', -- Use a specific model for commit messages
      default = 'sonnet',
      safe_terminal_commands = {
        'bin/bundle',
        'bundle',
        'bin/rspec',
        'rspec',
        'bin/rails',
        'rails',
        'bin/rake',
        'rake',
        'git commit',
        'mkdir',
        'touch',
      },
      guidelines = [[
Feel free to use any terminal tools - I have `fd`, `rg`, `gh`, `jq`, `aws` installed and ready to use.]],
    }
    require('telescope').setup {
      defaults = {
        mappings = {
          i = {
            ['<C-A>'] = function(prompt_bufnr)
              local action_state = require 'telescope.actions.state'

              local picker = action_state.get_current_picker(prompt_bufnr)
              local multi_selections = picker:get_multi_selection()

              if vim.tbl_isempty(multi_selections) then
                local selected_entry = action_state.get_selected_entry()
                if selected_entry and selected_entry.path then
                  local filepath = selected_entry.path
                  vim.cmd('Add ' .. filepath)
                else
                  vim.notify 'No selection'
                end
              else
                local files = vim.tbl_map(function(s)
                  return s.path
                end, multi_selections)
                vim.cmd('Add ' .. table.concat(files, ' '))
              end

              return true
            end,
          },
        },
      },
    }
    -- Add keybindings for llm-sidekick under <leader>s
    vim.keymap.set('n', '<leader>sc', ':vsplit | Chat<CR>', { noremap = true, silent = true, desc = 'Open Chat in vertical split' })
    vim.keymap.set('n', '<leader>sa', ':Accept<CR>', { noremap = true, silent = true, desc = 'Accept suggestion' })
    vim.keymap.set('n', '<leader>sA', ':Add<CR>', { noremap = true, silent = true, desc = 'Add suggestion' })
  end,
}
