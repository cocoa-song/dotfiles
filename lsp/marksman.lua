-- 마크다운 구조 LSP.
-- 헤딩을 문서 심볼로(→ gO 가 목차), [[위키링크]]/[](상대링크) 완성,
-- 링크 정의로 이동(gd), 헤딩 rename 시 걸려있는 링크까지 같이 수정.
return {
  cmd = { "marksman", "server" },
  filetypes = { "markdown" },
  -- .obsidian 을 루트 표시로 넣어야 볼트 전체가 한 워크스페이스로 잡힌다
  root_markers = { ".marksman.toml", ".obsidian", ".git" },
}
