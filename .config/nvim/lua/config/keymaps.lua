local map = vim.keymap.set

map("n", "<space>", "<nop>")
map("v", "<space>", "<nop>")

map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>no", "<cmd>noh<cr>", { desc = "Clear search highlight" })

map("n", "<C-u>", "<C-u>zz")
map("n", "<C-d>", "<C-d>zz")
map("n", "n", "nzz")
map("n", "N", "Nzz")

map("n", "L", "$")
map("n", "H", "^")
map("n", "U", "<C-r>")

map("n", "<C-h>", function()
  if vim.fn.exists(":TmuxNavigateLeft") ~= 0 then
    vim.cmd.TmuxNavigateLeft()
  else
    vim.cmd.wincmd("h")
  end
end, { desc = "Focus left split" })

map("n", "<C-j>", function()
  if vim.fn.exists(":TmuxNavigateDown") ~= 0 then
    vim.cmd.TmuxNavigateDown()
  else
    vim.cmd.wincmd("j")
  end
end, { desc = "Focus lower split" })

map("n", "<C-k>", function()
  if vim.fn.exists(":TmuxNavigateUp") ~= 0 then
    vim.cmd.TmuxNavigateUp()
  else
    vim.cmd.wincmd("k")
  end
end, { desc = "Focus upper split" })

map("n", "<C-l>", function()
  if vim.fn.exists(":TmuxNavigateRight") ~= 0 then
    vim.cmd.TmuxNavigateRight()
  else
    vim.cmd.wincmd("l")
  end
end, { desc = "Focus right split" })

map("i", "jj", "<esc>")
map("i", "JJ", "<esc>")

map("n", "<leader>f", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ async = true, timeout_ms = 500, lsp_format = "fallback" })
  end
end, { desc = "Format current buffer" })

map("n", "<leader>e", function()
  local ok, oil = pcall(require, "oil")
  if ok then
    oil.toggle_float()
  end
end, { desc = "Toggle Oil file explorer" })

map("n", "<leader>sf", function()
  local ok, builtin = pcall(require, "telescope.builtin")
  if ok then
    builtin.find_files({ hidden = true })
  end
end, { desc = "Find files" })

map("n", "<leader>sg", function()
  local ok, builtin = pcall(require, "telescope.builtin")
  if ok then
    builtin.live_grep()
  end
end, { desc = "Live grep" })

map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diff view" })
map("n", "<leader>gc", "<cmd>DiffviewClose<cr>", { desc = "Close diff view" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("config-lsp-keymaps", { clear = true }),
  callback = function(event)
    local bufnr = event.buf
    local opts = { buffer = bufnr }
    map("n", "gd", vim.lsp.buf.definition, opts)
    map("n", "gr", vim.lsp.buf.references, opts)
    map("n", "K", vim.lsp.buf.hover, opts)
    map("n", "<leader>rn", vim.lsp.buf.rename, opts)
    map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})
