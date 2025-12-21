return {
  {
    "CRAG666/code_runner.nvim",
    config = function()
      require("code_runner").setup({
        mode = "toggleterm",
        focus = true,
        startinsert = true,
        term = {
          position = "bottom",
          size = 8,
        },
        filetype = {
          python = "cd $dir && python3 -u",
          javascript = "cd $dir && node",
          typescript = "cd $dir && tsc $fileName && node $fileNameWithoutExt.js",
          rust = "cd $dir && cargo run",
          go = "cd $dir && go run",
          java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
          c = "cd $dir && gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
          cpp = "cd $dir && g++ $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
          lua = "cd $dir && lua",
          sh = "cd $dir && bash",
          vue = "cd $dir && npm run dev $end"
        }
      }
      )
    end
  }
}
