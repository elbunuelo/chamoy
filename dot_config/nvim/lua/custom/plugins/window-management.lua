local winmove = function(key)
  local curwin = vim.api.nvim_get_current_win()
  vim.cmd('wincmd ' .. key)
  if curwin == vim.api.nvim_get_current_win() then
    if string.match(key, '[jk]') then
      vim.cmd('wincmd s')
    else
      vim.cmd('wincmd v')
    end
    vim.cmd('wincmd ' .. key)
  end
end

-- Allow switching  and creating windows using ctrl + h|j|k|l
vim.keymap.set({ 'n' }, '<C-h>', function() winmove("h") end, { silent = true })
vim.keymap.set({ 'n' }, '<C-j>', function() winmove("j") end, { silent = true })
vim.keymap.set({ 'n' }, '<C-k>', function() winmove("k") end, { silent = true })
vim.keymap.set({ 'n' }, '<C-l>', function() winmove("l") end, { silent = true })

-- Close the current window using ctrl + w
vim.keymap.set({ 'n' }, '<C-x>', ':q<CR>', { silent = true })

return {}
