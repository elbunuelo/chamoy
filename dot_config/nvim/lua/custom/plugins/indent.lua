-- Enable persistent indentation when using > and <
-- Instead of allowing for just one indentation per key press
-- now it can be done multiple times.
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

return {}
