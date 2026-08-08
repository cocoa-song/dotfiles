-- LSP — Neovim 0.12 내장 방식
--
-- nvim-lspconfig 플러그인이 없다. 0.11 부터 `vim.lsp.config` / `vim.lsp.enable` 이
-- 코어에 들어왔고, 서버별 설정은 runtimepath 의 `lsp/<name>.lua` 에서 자동으로 읽힌다.
-- → 이 설정의 서버 정의는 ~/.config/nvim/lsp/*.lua 에 있다.

-- 모든 서버에 공통으로 얹히는 설정
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.enable({
  "lua_ls",   -- Lua (Neovim 플러그인 작성)
  "marksman", -- 마크다운 구조: 헤딩 심볼 · [[위키링크]] 완성 · 정의 이동 · rename
  -- "harper_ls", -- 영문 문법/맞춤법. 쓰려면 이 줄 주석 해제 + :MasonInstall harper-ls
})

-- 서버가 붙었을 때만 걸리는 키맵
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
  callback = function(ev)
    local map = function(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
    end

    map("grn", vim.lsp.buf.rename, "이름 바꾸기")
    map("gra", vim.lsp.buf.code_action, "코드 액션")
    map("grr", "<cmd>Telescope lsp_references<CR>", "참조 찾기")
    map("gd", "<cmd>Telescope lsp_definitions<CR>", "정의로 이동")
    map("gO", "<cmd>Telescope lsp_document_symbols<CR>", "문서 심볼(마크다운=목차)")
    map("K", vim.lsp.buf.hover, "호버")

    -- Lua 작성 중엔 인레이 힌트가 유용, 산문에선 방해
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/inlayHint") and vim.bo[ev.buf].filetype == "lua" then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
  end,
})

vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
})
