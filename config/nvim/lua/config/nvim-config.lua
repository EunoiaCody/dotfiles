local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = " "

opt.number = true -- 显示行号
opt.list = true -- 高亮当前选中的行

-- 设置tab 宽度
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Neovim 0.12+: 补全菜单边框
opt.pumborder = "rounded"

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

opt.splitbelow = true -- 水平分割窗口时在下方
opt.splitright = true -- 垂直分割窗口时在右侧
