return {
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
		opts = {
			override = {
				copilot = {
					icon = "",
					color = "#8A2BE2", -- Catppuccin.mocha.mauve
					name = "Copilot",
				},
			},
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons", "AndreM222/copilot-lualine" },
		opts = {
			options = {
				theme = "auto",
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { "filename" },
				lualine_x = {},
				lualine_y = { "fileformat", "filetype", "progress" },
				lualine_z = { "location" },
			},
			winbar = {
				lualine_a = { "filename" },
				lualine_b = { "location" },
				lualine_c = { "lsp_status" },
			},
		},
	},
	{
		"romgrk/barbar.nvim",
		event = "VeryLazy",
		dependencies = {
			"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
			"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {
			-- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
			animation = true,
			insert_at_start = true,
			auto_hide = true,
			-- …etc.
		},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
	},
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = { "BufReadPost", "BufNewFile" },
		submodules = false,
		main = "rainbow-delimiters.setup",
		opts = {},
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			-- add any options here
		},
		dependencies = { -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim", -- OPTIONAL:
			--   `nvim-notify` is only needed, if you want to use the notification view.
			--   If not available, we use `mini` as the fallback
			"rcarriga/nvim-notify",
			"hrsh7th/nvim-cmp",
		},

		config = function()
			require("noice").setup({
				lsp = {
					-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
					},
				},
				-- you can enable a preset for easier configuration
				presets = {
					bottom_search = true, -- use a classic bottom cmdline for search
					command_palette = true, -- position the cmdline and popupmenu together
					long_message_to_split = true, -- long messages will be sent to a split
					inc_rename = false, -- enables an input dialog for inc-rename.nvim
					lsp_doc_border = false, -- add a border to hover docs and signature help
				},
			})
		end,
	},
	{
		"folke/snacks.nvim",
		opts = {
			dashboard = {
				preset = {
					pick = function(cmd, opts)
						return LazyVim.pick(cmd, opts)()
					end,
					header = [[
███╗   ██╗███████╗ ██████╗ ███╗   ██╗ ██████╗ ██╗ █████╗ 
████╗  ██║██╔════╝██╔═══██╗████╗  ██║██╔═══██╗██║██╔══██╗
██╔██╗ ██║█████╗  ██║   ██║██╔██╗ ██║██║   ██║██║███████║
██║╚██╗██║██╔══╝  ██║   ██║██║╚██╗██║██║   ██║██║██╔══██║
██║ ╚████║███████╗╚██████╔╝██║ ╚████║╚██████╔╝██║██║  ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═╝
         ]],
                -- stylua: ignore
                ---@type snacks.dashboard.Item[]
                keys = {{
                    icon = " ",
                    key = "f",
                    desc = "查找文件",
                    action = ":lua Snacks.dashboard.pick('files')"
                }, {
                    icon = " ",
                    key = "n",
                    desc = "新建文件",
                    action = ":ene | startinsert"
                }, {
                    icon = " ",
                    key = "g",
                    desc = "查找文本",
                    action = ":lua Snacks.dashboard.pick('live_grep')"
                }, {
                    icon = " ",
                    key = "r",
                    desc = "最近文件",
                    action = ":lua Snacks.dashboard.pick('oldfiles')"
                }, {
                    icon = " ",
                    key = "p",
                    desc = "项目",
                    action = function()
                        Snacks.picker.projects({
                            on_confirm = function(_, item)
                                if not item then
                                    return
                                end

                                local dir = item.cwd or item.path or item.dir
                                if not dir or dir == "" then
                                    return
                                end

                                vim.cmd("e " .. vim.fn.fnameescape(dir))
                            end
                        })
                    end
                }, {
                    icon = " ",
                    key = "c",
                    desc = "配置文件",
                    action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})"
                }, {
                    icon = " ",
                    key = "q",
                    desc = "退出",
                    action = ":qa"
                }}
,
				},
			},
		},
	},
}
