return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
      vim.keymap.set("n", "]c", function() require("gitsigns").next_hunk() end, { desc = "Next hunk" })
      vim.keymap.set("n", "[c", function() require("gitsigns").prev_hunk() end, { desc = "Prev hunk" })
    end,
  },
}
