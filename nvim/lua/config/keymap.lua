local map = vim.keymap.set

-- 更好的光标上下滚动
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "下", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "下", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "上", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "上", expr = true, silent = true })

-- 使用 <ctrl> + <h | j | k | l> 切换窗口
map("n", "<C-h>", "<C-w>h", { desc = "前往左窗口", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "前往下窗口", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "前往上窗口", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "前往右窗口", remap = true })

-- 使用 <ctrl> + 方向键 调整窗口大小
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "增加窗口高度" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "减小窗口高度" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "减小窗口宽度" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "增加窗口宽度" })

-- 打开lazy.nvim
map("n", "<leader>l", "<CMD>Lazy<CR>", { desc = "[Lazy] Open lazy.nvim" })

-- Nvim Tree
map("n", "<leader>nto", "<CMD>NvimTreeOpen<CR>", { desc = "打开 Nvim Tree" }) -- 打开 nvim-tree.nvim
map("n", "<leader>ntc", "<CMD>NvimTreeClose<CR>", { desc = "关闭 Nvim Tree" }) -- 关闭 nvim-tree.nvim

-- 复制粘贴
map("v", "<ctrl>C", "\"+y", { desc = "复制到系统剪贴板" })
map("x", "<ctrl>C", "\"+yy", { desc = "复制到系统剪贴板" })
map("v", "<ctrl>V", "\"+p", { desc = "粘贴自系统剪贴板"})
map("x", "<ctrl>V", "\"+pp", { desc = "粘贴自系统剪贴板"})

-- 打开 Copilot Chat 
map("n", "<leader>coc", "<CMD>CodeCompanionChat<CR>", { desc = "打开 Copilot Chat" })

map("n", "<leader>C", "<cmd>MonokaiProSelect<cr>", { desc = "Select Monokai pro filter" })
