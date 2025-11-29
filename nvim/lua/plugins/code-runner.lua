return {
  {
    "CRAG666/code_runner.nvim",
    config = function ()
      require("code_runner").setup({
        mode = "toggleterm",
        focus = true,
        startinsert = true,
        term = {
          position = "bottom",
          size = 8,
        },
        filetype = {
          python = "python3 -u",
          javascript = "node",
          typescript = "deno run",
          rust = "cargo run",
          go = "go run",
          java = "javac $fileName && java $fileNameWithoutExt",
          c = "gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
          cpp = "g++ $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
          lua = "lua",
          sh = "bash",
        }
      }
    )
    end
  }
}
