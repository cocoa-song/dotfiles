-- markdown-oxide — PKM 마크다운 언어 서버
-- https://github.com/Feel-ix-343/markdown-oxide
--
-- 노트 기능을 플러그인이 아니라 LSP 로 제공한다:
--   [[위키링크]] 완성 · 백링크(references) · 태그 · 헤딩/블록 참조
--   데일리 노트 · 미해결 링크 진단
--
-- ★ 경로를 설정에 박지 않는다. root_markers 로 버퍼마다 노트 루트를 찾으므로
--   ~/notes 와 Obsidian 볼트가 각각 독립된 노트 저장소로 동시에 동작한다.
--   (~/notes/.moxide.toml · 볼트/.obsidian)

---@param client vim.lsp.Client
---@param bufnr integer
---@param cmd string
local function jump(client, bufnr, cmd)
  return client:exec_cmd({
    title = ("Markdown-Oxide-%s"):format(cmd),
    command = "jump",
    arguments = { cmd },
  }, { bufnr = bufnr })
end

---@type vim.lsp.Config
return {
  cmd = { "markdown-oxide" },
  filetypes = { "markdown" },
  -- .moxide.toml 을 먼저 본다 — 노트 저장소를 명시적으로 표시한 것이므로
  -- 상위의 .git 보다 우선해야 한다
  root_markers = { ".moxide.toml", ".obsidian", ".git" },

  on_attach = function(client, bufnr)
    -- :LspToday / :LspTomorrow / :LspYesterday
    for _, cmd in ipairs({ "today", "tomorrow", "yesterday" }) do
      local name = "Lsp" .. cmd:gsub("^%l", string.upper)
      vim.api.nvim_buf_create_user_command(bufnr, name, function()
        jump(client, bufnr, cmd)
      end, { desc = ("%s 데일리 노트 열기"):format(cmd) })
    end
  end,
}
