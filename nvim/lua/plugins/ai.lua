return {
	{
		"zbirenbaum/copilot.lua", -- 改用 lua 版本，性能更好
		event = "InsertEnter",
		cmd = "Copilot",
		config = function()
			require("copilot").setup({
				suggestion = { enabled = false }, -- 如果使用 blink-cmp-copilot
				panel = { enabled = false },
			})
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		version = "v17.33.0",
		cmd = { "CodeCompanion", "CodeCompanionEdit" },
		opts = {
			language = "Chinese",
			send_code = true,
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},
}
