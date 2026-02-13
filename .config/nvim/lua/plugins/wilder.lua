return {
	{
		"gelguy/wilder.nvim",
		keys = {
			":",
			"/",
			"?",
		},
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		build = function()
			if vim.fn.exists(":UpdateRemotePlugins") == 2 then
				vim.cmd("silent! UpdateRemotePlugins")
			end
		end,
		config = function()
			local wilder = require("wilder")

			-- Enable wilder when pressing :, / or ?
			wilder.setup({ modes = { ":", "/", "?" } })

			-- Enable fuzzy matching for commands and buffers
			wilder.set_option("pipeline", {
				wilder.branch(
					wilder.cmdline_pipeline({
						fuzzy = 1,
					}),
					wilder.vim_search_pipeline({
						fuzzy = 1,
					})
				),
			})

			wilder.set_option(
				"renderer",
				wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
					highlighter = wilder.basic_highlighter(),
					pumblend = 5,
					min_width = "100%",
					min_height = "25%",
					max_height = "25%",
					border = "rounded",
					left = { " ", wilder.popupmenu_devicons() },
					right = { " ", wilder.popupmenu_scrollbar() },
				}))
			)
		end,
	},
}
