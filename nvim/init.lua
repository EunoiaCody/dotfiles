-- neovim config
require("config.nvim-config")
require("config.keymap")

-- neovide fontsize
require("config.neovide-config")

-- lazy.nvim
require("config.lazy") -- 使用 lazy.nvim 作为 neovim 的插件管理器
require("config.lsp-config") -- LSP 配置注册（vim.lsp.config 不启动服务器，可安全提前调用）
require("config.plugins-config")

-- Vue LSP 配置需要在 vim.lsp.enable 之前注册
-- 如果 vue-language-server 尚未安装，vtsls/vue_ls 会在安装后自动启用
local vue_ls_ok, _ = pcall(require, "config.vue-config")
if not vue_ls_ok then
	vim.notify("vue-config 加载失败，请确保 vue-language-server 已安装", vim.log.levels.WARN)
end