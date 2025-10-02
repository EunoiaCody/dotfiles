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
