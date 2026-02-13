return {
	{
		"kepano/flexoki-neovim",
		name = "flexoki",
		lazy = false,
		priority = 1000,
		config = function()
			local variant = vim.o.background == "light" and "flexoki-light" or "flexoki-dark"
			vim.cmd.colorscheme(variant)
		end,
	},
}
