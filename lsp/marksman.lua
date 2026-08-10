-- 마크다운 구조 LSP. **현재 비활성** — markdown_oxide 로 대체됨.
--
-- 되돌리려면 lua/config/lsp.lua 의 vim.lsp.enable 목록에서
-- "markdown_oxide" 를 "marksman" 으로 바꾼다. 바이너리는 brew 로 설치돼 있다.
-- 둘을 동시에 켜지 말 것 — 같은 버퍼에 붙어 링크 완성 후보가 중복된다.
--
-- 헤딩을 문서 심볼로(→ gO 가 목차), [[위키링크]]/[](상대링크) 완성,
-- 링크 정의로 이동(gd), 헤딩 rename 시 걸려있는 링크까지 같이 수정.
return {
  cmd = { "marksman", "server" },
  filetypes = { "markdown" },
  -- .obsidian 을 루트 표시로 넣어야 볼트 전체가 한 워크스페이스로 잡힌다
  root_markers = { ".marksman.toml", ".obsidian", ".git" },
}
