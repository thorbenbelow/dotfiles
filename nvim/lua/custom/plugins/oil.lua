return {
  'stevearc/oil.nvim',
  opts = {
    default_file_explorer = true,
  },
  config = function(_, opts)
    require('oil').setup(opts)
    -- Open parent directory in oil
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
  end,
}