return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"echasnovski/mini.nvim", -- Optional for UI enhancements
		},
	},
	{
		"renerocksai/telekasten.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "mattn/calendar-vim" },
		opts = {
			home = vim.fn.expand("~/notes"),
			dailies = vim.fn.expand("~/notes/dailies"),
			templates = vim.fn.expand("~/notes/templates"),
			template_new_daily = vim.fn.expand("~/notes/templates/daily.md"),
		},
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install && git restore .",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
}
