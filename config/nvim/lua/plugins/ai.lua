return {
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
	{
		"yetone/avante.nvim",
		build = "make",
		event = "VeryLazy",
		version = false,
		---@module 'avante'
		---@type avante.Config
		opts = {
			instructions_file = "avante.md",
			provider = "opencode",
			providers = {
				opencode = {
					__inherited_from = "openai",
					endpoint = "https://opencode.ai/zen/go/v1",
					model = "glm-5.1",
					api_key_name = "AVANTE_OPENCODE_API_KEY",
					timeout = 30000,
					extra_request_body = {
						temperature = 0.75,
						max_tokens = 20480,
					},
				},
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"OXY2DEV/markview.nvim",
			"nvim-tree/nvim-web-devicons",
		},
	},
}