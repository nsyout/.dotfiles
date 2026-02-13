return {
	{
		"nvim-pack/nvim-spectre",
		lazy = true,
		cmd = { "Spectre" },
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("spectre").setup({
				mapping = {
					["send_to_qf"] = {
						map = "<C-q>",
						cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
						desc = "send all items to quickfix",
					},
				},
				-- replace_engine = {
				-- 	sed = {
				-- 		cmd = "sed",
				-- 		args = {
				-- 			"-i",
				-- 			"",
				-- 			"-E",
				-- 		},
				-- 	},
				-- },
			})
		end,
	},
}
