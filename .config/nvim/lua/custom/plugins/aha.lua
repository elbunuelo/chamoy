local PLUGIN_DIR = '~/Projects/aha/aha.nvim'

if (vim.uv or vim.lop).fs_stat(PLUGIN_DIR) then
  return {
    { dir = PLGUIN_DIR },
  }
end

return {}
