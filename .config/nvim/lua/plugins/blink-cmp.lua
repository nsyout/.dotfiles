return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "v1.*",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
    },
    opts = {
      keymap = {
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-c>"] = { "cancel", "fallback" },
        ["<CR>"] = { "select_and_accept", "fallback" },
        ["<C-Space>"] = { "show", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      snippets = { preset = "luasnip" },
      completion = {
        menu = { border = "rounded" },
        documentation = { auto_show = true, window = { border = "rounded" } },
      },
      signature = {
        enabled = true,
        window = { border = "rounded" },
      },
    },
  },
}
