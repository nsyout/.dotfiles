return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 400,
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Harpoon" },
        { "<leader>n", group = "Search" },
        { "<leader>s", group = "Search" },
      })
    end,
  },
}
