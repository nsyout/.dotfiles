return {
  {
    "L3MON4D3/LuaSnip",
    version = "2.*",
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local ls = require("luasnip")
      ls.config.setup({
        history = true,
        enable_autosnippets = true,
      })
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
