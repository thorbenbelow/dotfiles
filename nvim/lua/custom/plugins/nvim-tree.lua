return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require('nvim-tree').setup {}

    -- Keymap to toggle nvim-tree
    vim.keymap.set('n', '<leader>t', ':NvimTreeToggle<CR>', {
      desc = 'Toggle file explorer',
    })
  end,
}
