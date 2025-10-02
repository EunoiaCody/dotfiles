vim.cmd[[colorscheme dracula]]

require("overseer").setup({
  templates = { "builtin", "user.cpp_build" },
})
