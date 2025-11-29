vim.cmd([[colorscheme catppuccin]])

require("toggleterm").setup({})

function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	-- 将 <esc> 键映射为退出终端模式
	vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
	-- 将 jk 键组合映射为退出终端模式
	vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
	-- 额外的映射，如用于窗口移动的 <C-h/j/k/l>
	vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
	-- ... 其他窗口移动映射 ...
end

-- 在任何终端打开时自动应用这些映射
vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

-- 配置 notify 插件的背景颜色为透明色
require("notify").setup({
	background_colour = "#000000",
})

-- conform 配置
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function(args)
		require("conform").format({ bufnr = args.buf })
	end,
})

vim.api.nvim_create_user_command("Format", function(args)
	local range = nil
	if args.count ~= -1 then
		local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
		range = {
			start = { args.line1, 0 },
			["end"] = { args.line2, end_line:len() },
		}
	end
	require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })
