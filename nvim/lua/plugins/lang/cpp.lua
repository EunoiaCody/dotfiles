return {
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = {
      ensure_installed = {
        "clangd",
      },
    },
    opts_extend = { "ensure_installed" },
  },

  {
    "williamboman/mason.nvim",
    optional = true,
    opts = {
      ensure_installed = {
        "clangd",
      },
    },
    opts_extend = { "ensure_installed" },
  }
}
