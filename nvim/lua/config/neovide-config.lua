if vim.g.neovide then
	vim.keymap.set(
		{ "n", "v" },
		"<C-ScrollWheelUp>",
		":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>"
	)
	vim.keymap.set(
		{ "n", "v" },
		"<C-ScrollWheelDown>",
		":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>"
	)
	vim.g.neovide_window_blurred = true
	vim.g.neovide_opacity = 0.9 -- 背景透明
	vim.g.neovide_normal_opacity = 0.6
end
