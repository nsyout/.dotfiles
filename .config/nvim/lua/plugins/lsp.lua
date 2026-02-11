return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "folke/lazydev.nvim",
    },
    config = function()
      local servers = {
        bashls = {},
        cssls = {},
        html = {},
        jsonls = {},
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              workspace = { checkThirdParty = false },
              telemetry = { enabled = false },
            },
          },
        },
        marksman = {},
        yamlls = {},
      }

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then
        capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
      end

      require("mason").setup({ ui = { border = "rounded" } })
      require("mason-lspconfig").setup()
      require("mason-tool-installer").setup({
        ensure_installed = vim.tbl_keys(servers),
        auto_update = false,
        run_on_start = false,
      })

      for name, config in pairs(servers) do
        vim.lsp.config(name, vim.tbl_deep_extend("force", config, { capabilities = capabilities }))
        vim.lsp.enable(name)
      end
    end,
  },
}
