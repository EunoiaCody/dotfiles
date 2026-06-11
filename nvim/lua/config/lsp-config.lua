-- LSP 配置使用 Neovim 0.12 的 vim.lsp.config() API
-- nvim-lspconfig 提供服务器默认配置，此处只需覆盖需要自定义的部分
-- mason-lspconfig 自动将 Mason 安装的服务器桥接到 vim.lsp.enable()，无需手动启用

-- lua_ls: 添加 Neovim 开发专用的 settings
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME },
			},
			completion = { callSnippet = "Replace" },
		},
	},
})