-- Additional keymaps for telescope, Ctrl + p and \ for searching files and grepping, respectively
vim.keymap.set('n', '<leader>p', require('telescope.builtin').find_files, { desc = 'Search Files' })
-- Searcch files including hidden
vim.keymap.set('n', '<leader>P', function()
  require('telescope.builtin').find_files {
    prompt_title = 'Find +hidden',
    find_command = { 'rg', '--ignore', '--files', '--hidden', '--iglob=!.git/**/*' },
  }
end, { desc = 'Search including hidden files' })

vim.keymap.set('n', '<leader>??', require('telescope.builtin').help_tags, { desc = 'Search help' })

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local conf = require('telescope.config').values

local live_multigrep = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == '' then
        return nil
      end

      local parts = vim.split(prompt, '  ')
      local args = { 'rg' }

      for i, part in ipairs(parts) do
        if i == 1 then
          table.insert(args, '-e')
          table.insert(args, part)
        elseif i == 2 then
          table.insert(args, '-g')
          table.insert(args, part)
        else
          table.insert(args, part)
        end
      end

      return vim.list_extend(args, { '--color=never', '--no-heading', '--with-filename', '--line-number', '--column', '--smart-case' })
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = 'Multi Grep',
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require('telescope.sorters').empty(),
    })
    :find()
end

vim.keymap.set('n', '\\', live_multigrep, { desc = 'Search by Grep' })

return {}
