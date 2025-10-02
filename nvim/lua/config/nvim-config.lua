local opt = vim.opt

opt.number = true -- 显示行号
opt.list = true -- 高亮当前选中的行

-- 设置为tab 宽度
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- vim.cmd("language en_US.UTF-8") -- 设置语言为英语

vim.g.mapleader = ' ' -- 设置为<leader> 为 ' '

opt.splitbelow = true -- 水平分割窗口时在下方
opt.splitright = true -- 垂直分割窗口时在右侧

