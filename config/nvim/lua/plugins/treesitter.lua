return {

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		lazy = false,
		event = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")
			local query = require("vim.treesitter.query")

			local non_filetype_match_injection_language_aliases = {
				ex = "elixir",
				pl = "perl",
				sh = "bash",
				uxn = "uxntal",
				ts = "typescript",
			}

			local html_script_type_languages = {
				["importmap"] = "json",
				["module"] = "javascript",
				["application/ecmascript"] = "javascript",
				["text/ecmascript"] = "javascript",
			}

			local function get_parser_from_markdown_info_string(injection_alias)
				local match = vim.filetype.match({ filename = "a." .. injection_alias })
				return match or non_filetype_match_injection_language_aliases[injection_alias] or injection_alias
			end

			-- Neovim 0.12+ passes capture arrays to directives; use force=true to override defaults.
			local opts = { force = true, all = false }

			query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
				local node = match[pred[2]]
				if type(node) == "table" then
					node = node[1]
				end
				if not node then
					return
				end
				local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
				local configured = html_script_type_languages[type_attr_value]
				if configured then
					metadata["injection.language"] = configured
				else
					local parts = vim.split(type_attr_value, "/", {})
					metadata["injection.language"] = parts[#parts]
				end
			end, opts)

			query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
				local node = match[pred[2]]
				if type(node) == "table" then
					node = node[1]
				end
				if not node then
					return
				end
				local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
				metadata["injection.language"] = get_parser_from_markdown_info_string(injection_alias)
			end, opts)

			query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
				local id = pred[2]
				local node = match[id]
				if type(node) == "table" then
					node = node[1]
				end
				if not node then
					return
				end
				local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
				if not metadata[id] then
					metadata[id] = {}
				end
				metadata[id].text = string.lower(text)
			end, opts)

			-- Parser management via nvim-treesitter (ensure_installed + auto_install).
			-- Highlight and indent are handled natively by Neovim 0.12+.
			configs.setup({
				ensure_installed = {
					"cpp",
					"python",
					"lua",
					"vim",
					"vimdoc",
					"html",
					"markdown",
					"markdown_inline",
					"javascript",
					"typescript",
					"vue",
				},
				sync_install = false,
				auto_install = true,
			})
		end,
	},
}