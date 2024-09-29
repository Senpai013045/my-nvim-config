return {
	"catppuccin/nvim",
	priority = 1000,
	init = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = true,
		})
		vim.cmd.colorscheme("catppuccin")
		vim.cmd.hi("Comment gui=none")
	end,
}
