return {

  {
    "mason-org/mason.nvim",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "python",
        "cpp",
        "javascript",
        "typescript",
        "clangd",
        "gopls",
        "rust-analyzer",
      },
      ui = {
        icon = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
        },
      },
    },
  },

}
