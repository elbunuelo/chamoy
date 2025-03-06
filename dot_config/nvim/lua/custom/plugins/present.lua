local local_dir = '~/Projects/present.nvim'
if vim.fn.isdirectory(local_dir) ~= 0 then
  return {
    {
      dir = local_dir,
    }
  }
end
return {}
