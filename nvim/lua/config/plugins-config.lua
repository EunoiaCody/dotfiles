vim.cmd[[colorscheme dracula]]

require("overseer").setup({
  templates = { "builtin", "user.cpp_build" },
})

require("toggleterm").setup{}

function _G.set_terminal_keymaps()
  local opts = {buffer = 0}
  -- 将 <esc> 键映射为退出终端模式
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  -- 将 jk 键组合映射为退出终端模式
  vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
  -- 额外的映射，如用于窗口移动的 <C-h/j/k/l>
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  -- ... 其他窗口移动映射 ...
end

-- 在任何终端打开时自动应用这些映射
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
