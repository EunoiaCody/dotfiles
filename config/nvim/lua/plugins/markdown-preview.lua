return {
	"OXY2DEV/markview.nvim",
	lazy = false,
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	---@module 'markview'
	---@type markview.config
	opts = {
		preview = {
			filetypes = { "markdown", "codecompanion", "quarto" },
			modes = { "n", "c", "t" },
			hybrid_modes = { "n" },
		},
		latex = {
			enable = true,
		},
	},
	config = function(_, opts)
		require("markview").setup(opts)
	end,
}