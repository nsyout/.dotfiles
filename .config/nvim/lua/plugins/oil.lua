return {
  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      view_options = { show_hidden = true },
      float = { border = "rounded" },
      confirmation = { border = "rounded" },
    },
  },
}
