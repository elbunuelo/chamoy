-- Reference: https://jdhao.github.io/2021/09/09/nvim_use_virtual_text/
local function update_title()
  local buffer_number = vim.fn.bufnr('%')
  local namespace = vim.api.nvim_create_namespace('buffer_title')
  local first_visible_line = vim.fn.line('w0') - 1
  local cursor_line = vim.fn.line('.') - 1
  local column = 0

  -- Clear existing extmarks in the namespace
  vim.api.nvim_buf_clear_namespace(buffer_number, namespace, 0, -1)

  -- Get current mode
  local current_mode = vim.api.nvim_get_mode().mode
  -- Check for all insert mode variants
  local is_insert = current_mode:find('^i') or current_mode:find('^R') or current_mode:find('^niI')

  -- Only show title if not in insert mode and cursor is not on first visible line
  if not is_insert and cursor_line ~= first_visible_line then
    local options = {
      id = 1,
      virt_text = { { vim.fn.expand('%:t'), "@comment" } },
      virt_text_pos = 'right_align',
      virt_lines_above = true, -- Place the text above the first visible line
      priority = 100           -- High priority to ensure visibility
    }

    vim.api.nvim_buf_set_extmark(buffer_number, namespace, first_visible_line, column, options)
  end
end

vim.api.nvim_create_autocmd(
  { "BufEnter", "WinScrolled", "InsertEnter", "InsertLeave", "ModeChanged", "CursorMoved", "CursorMovedI" }, {
    callback = update_title
  })

return {}
