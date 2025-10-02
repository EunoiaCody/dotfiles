return {
  'MeanderingProgrammer/render-markdown.nvim',
  {'nvim-mini/mini.nvim', version = '*'},

  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
  opts = {},
  
  config = function ()
    require('render-markdown').setup({
      enabled = true,
      file_types = { 'markdown', 'quarto' },
      render_modes = { 'n', 'c', 't' },
      latex = {
        enabled = true,
        render_modes = false,
        converter = { 'utftex', 'latex2text' },
        highlight = 'RenderMarkdownMath',
        position = 'center',
        top_pad = 0,
        bottom_pad = 0,
      },
      injections = {
        gitcommit = {
          enabled = true,
          query = [[
            ((message) @injection.content
                (#set! injection.combined)
                (#set! injection.include-children)
                (#set! injection.language "markdown"))
          ]],
        },
      },
    })
  end
}
