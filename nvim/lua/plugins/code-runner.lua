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
					size = 15,
				},
				filetype = {
					python = "cd $dir && python3 -u $fileName",
					javascript = "cd $dir && node $fileName",
					typescript = "cd $dir && tsc $fileName && node $fileNameWithoutExt.js",
					rust = "cd $dir && rustc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
					go = "cd $dir && go run",
					java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
					c = "cd $dir && gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
					cpp = "cd $dir && g++ $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
					lua = "cd $dir && lua",
					sh = "cd $dir && bash",
					vue = "cd $dir && npm run dev $end",
				},
			})
		end,
	},
}
