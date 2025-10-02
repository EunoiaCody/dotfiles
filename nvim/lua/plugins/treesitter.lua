return {

  {
    "nvim-treesitter/nvim-treesitter", 
    branch = 'master', 
    lazy = false, 
    build = ":TSUpdate",
    config = function ()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = {
          "cpp",
          "python",
          "lua",
          "vim",
          "vimdoc",
          "html",
          "markdown",
          "markdown_inline",
          "javascript",
          "typescript"
        },
        sync_install = false,
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  }

}
