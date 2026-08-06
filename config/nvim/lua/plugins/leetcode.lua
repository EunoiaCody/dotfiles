return {
	"kawre/leetcode.nvim",
	cmd = "Leet",

	build = ":TSUpdate html", -- if you have `nvim-treesitter` installed
	dependencies = {
		-- include a picker of your choice, see picker section for more details
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
	},
	opts = {
		-- configuration goes here
		---@type lc.lang
		lang = "cpp",
		cn = {
			enabled = flase, ---@type boolean
			translater = true, ---@type boolean
			translate_problem = true, ---@type boolean
		},
		---@type lc.storage
		storage = {
			home = vim.fn.stdpath("data") .. "/leetcode.nvim",
			cache = vim.fn.stdpath("cache") .. "/leetcode.nvim",
		},
	},
}
