return {
	{
		"RRethy/base16-nvim",
		priority = 1000,
		config = function()
			require('base16-colorscheme').setup({
				base00 = '#181825',
				base01 = '#181825',
				base02 = '#9994a0',
				base03 = '#9994a0',
				base04 = '#f6efff',
				base05 = '#fbf8ff',
				base06 = '#fbf8ff',
				base07 = '#fbf8ff',
				base08 = '#ff9fb1',
				base09 = '#ff9fb1',
				base0A = '#d8b7ff',
				base0B = '#a5ffba',
				base0C = '#ead9ff',
				base0D = '#d8b7ff',
				base0E = '#dfc4ff',
				base0F = '#dfc4ff',
			})

			vim.api.nvim_set_hl(0, 'Visual', {
				bg = '#9994a0',
				fg = '#fbf8ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Statusline', {
				bg = '#d8b7ff',
				fg = '#181825',
			})
			vim.api.nvim_set_hl(0, 'LineNr', { fg = '#9994a0' })
			vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#ead9ff', bold = true })

			vim.api.nvim_set_hl(0, 'Statement', {
				fg = '#dfc4ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Keyword', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Repeat', { link = 'Statement' })
			vim.api.nvim_set_hl(0, 'Conditional', { link = 'Statement' })

			vim.api.nvim_set_hl(0, 'Function', {
				fg = '#d8b7ff',
				bold = true
			})
			vim.api.nvim_set_hl(0, 'Macro', {
				fg = '#d8b7ff',
				italic = true
			})
			vim.api.nvim_set_hl(0, '@function.macro', { link = 'Macro' })

			vim.api.nvim_set_hl(0, 'Type', {
				fg = '#ead9ff',
				bold = true,
				italic = true
			})
			vim.api.nvim_set_hl(0, 'Structure', { link = 'Type' })

			vim.api.nvim_set_hl(0, 'String', {
				fg = '#a5ffba',
				italic = true
			})

			vim.api.nvim_set_hl(0, 'Operator', { fg = '#f6efff' })
			vim.api.nvim_set_hl(0, 'Delimiter', { fg = '#f6efff' })
			vim.api.nvim_set_hl(0, '@punctuation.bracket', { link = 'Delimiter' })
			vim.api.nvim_set_hl(0, '@punctuation.delimiter', { link = 'Delimiter' })

			vim.api.nvim_set_hl(0, 'Comment', {
				fg = '#9994a0',
				italic = true
			})

			local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/dankcolors.lua"
			if not _G._matugen_theme_watcher then
				local uv = vim.uv or vim.loop
				_G._matugen_theme_watcher = uv.new_fs_event()
				_G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
					local new_spec = dofile(current_file_path)
					if new_spec and new_spec[1] and new_spec[1].config then
						new_spec[1].config()
						print("Theme reload")
					end
				end))
			end
		end
	}
}
