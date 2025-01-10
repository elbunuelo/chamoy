local PLUGIN_DIR = '~/Projects/floatnote.nvim/'

if (vim.uv or vim.lop).fs_stat(PLUGIN_DIR) then
  return {
    { dir = PLGUIN_DIR },
  }
end

return {
  'elbunuelo/floatnote.nvim',
  dependencies = {
    'zk-org/zk-nvim',
  },
}
