-- 영문 문법·맞춤법 검사 (로컬 실행, Grammarly 대안. Automattic 관리).
--
-- 기본 비활성 — 한국어를 지원하지 않아 한글 문서에서는 진단이 시끄럽다.
-- 영문 문서를 쓸 때만 켜는 걸 권함:
--   1) brew install harper   (mason.nvim 을 쓰지 않는다 — 외부 도구는 전부 brew)
--   2) lua/config/lsp.lua 의 vim.lsp.enable 목록에서 "harper_ls" 주석 해제
--   또는 그때그때 :lua vim.lsp.enable("harper_ls")
return {
  cmd = { "harper-ls", "--stdio" },
  filetypes = { "markdown" },
  root_markers = { ".git", ".obsidian" },
  settings = {
    ["harper-ls"] = {
      userDictPath = vim.fn.stdpath("config") .. "/harper-dict.txt",
      linters = {
        SentenceCapitalization = false, -- 노트엔 소문자 단편이 많다
        SpellCheck = true,
        LongSentences = false,
      },
      isolateEnglish = true, -- 비영어 구간(한글)은 건너뛴다
    },
  },
}
