return {
  'L3MON4D3/LuaSnip',
  build = 'make install_jsregexp', -- 编译 Luasnip 的依赖
  dependencies = {
    'rafamadriz/friendly-snippets',
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
    end,
  },

  opts = {
    enable_snipmate_style = false,

    ext_paths = {
      '~/.config/nvim/snippets',
    },
  },
}
