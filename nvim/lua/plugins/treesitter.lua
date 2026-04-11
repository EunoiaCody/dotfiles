return {

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		lazy = false,
		evevt = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")
			local query = require("vim.treesitter.query")

			local function unwrap_capture(match, id)
				local value = match[id]
				if type(value) == "table" then
					return value[1]
				end
				return value
			end

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

			local opts = vim.fn.has("nvim-0.10") == 1 and { force = true, all = false } or true

			-- Neovim 0.12 can pass capture arrays to directives used by nvim-treesitter.
			-- Re-register directives with capture unwrapping so get_node_text always receives a TSNode.
			query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
				local node = unwrap_capture(match, pred[2])
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
				local node = unwrap_capture(match, pred[2])
				if not node then
					return
				end
				local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
				metadata["injection.language"] = get_parser_from_markdown_info_string(injection_alias)
			end, opts)

			query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
				local id = pred[2]
				local node = unwrap_capture(match, id)
				if not node then
					return
				end
				local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
				if not metadata[id] then
					metadata[id] = {}
				end
				metadata[id].text = string.lower(text)
			end, opts)

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
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
}
