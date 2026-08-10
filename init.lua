-- 마크다운 워크벤치 · Neovim 0.12+
--
-- 설계 원칙
--   1. 0.12에 있는 건 플러그인으로 다시 깔지 않는다.
--      (treesitter 파서 · LSP 클라이언트 설정 · 스니펫 — 전부 내장)
--   2. 플러그인 관리는 내장 vim.pack. 서드파티 부트스트랩 코드 없음.
--   3. 마크다운은 코드가 아니라 산문이다 — ftplugin/markdown.lua 에서 뒤집는다.
--
-- 구조
--   lua/config/*   내 설정
--   lsp/<name>.lua LSP 서버별 설정 (vim.lsp.enable 이 runtimepath 에서 자동 로드)
--   ftplugin/*     파일타입별 설정

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("이 설정은 Neovim 0.12+ 가 필요합니다 (현재: " .. tostring(vim.version()) .. ")", vim.log.levels.ERROR)
  return
end

require("config.options")
require("config.plugins")
require("config.completion")
require("config.lsp")
require("config.keymaps")
require("config.ime")
