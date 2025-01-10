local PLUGIN_DIR = '~/Projects/training-wheels.nvim'

if (vim.uv or vim.lop).fs_stat(PLUGIN_DIR) then
  return {
    { dir = PLGUIN_DIR },
  }
end

return {}
