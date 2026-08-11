-- 자동완성 — Neovim 0.12 내장 (blink.cmp 제거)
--
-- 0.12 에 'autocomplete' 옵션이 들어오면서 플러그인 없이도 쓸 만해졌다.
-- 여러 소스를 한 팝업에 병합하는 건 'complete' 가 담당한다:
--   .  현재 버퍼   w  다른 창의 버퍼   b  로드된 버퍼
--   o  omnifunc(= LSP. vim.lsp.completion.enable 이 설정한다)
--   F{func}  임의 함수 (여러 개 등록 가능)
-- 소스 뒤의 ^N 은 그 소스에서 가져올 후보 개수 상한.
--
-- 내부적으로 감쇠 타임슬라이스로 돌아간다 — 앞선 소스에 시간을 더 주고
-- 느린 소스는 빠르게 강등하되 전부 실행한다. 'complete' 에 F/o 가 있으면
-- LSP 를 위해 타임아웃을 ~1s 로 늘린다. (:h ins-autocompletion)

vim.o.autocomplete = true
vim.o.autocompletedelay = 80 -- 타이핑 중 깜빡임 방지
vim.o.completeopt = "menuone,noselect,popup,fuzzy"

-- 기본 소스는 버퍼 계열만. LSP(o)는 서버가 붙은 버퍼에서만 더한다(lsp.lua).
vim.o.complete = ".^5,w^5,b^5"

-- noselect 라 아무것도 선택돼 있지 않다 → Enter 는 그냥 줄바꿈.
-- 산문에서 이게 핵심이다. 의식적으로 <C-n> 으로 고른 뒤에만 Enter 가 확정한다.
local function selected()
  return vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1
end

vim.keymap.set("i", "<CR>", function()
  return selected() and "<C-y>" or "<CR>"
end, { expr = true, desc = "선택했으면 확정, 아니면 줄바꿈" })

-- 팝업이 떠 있을 때만 Tab 이 후보 순회. 아니면 원래 Tab(마크다운 리스트 들여쓰기).
vim.keymap.set("i", "<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, { expr = true })

vim.keymap.set("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

-- 스니펫 자리 이동 — vim.snippet 은 0.12 내장이라 LuaSnip 이 필요 없다
vim.keymap.set({ "i", "s" }, "<C-l>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1)
  end
end, { desc = "스니펫 다음 자리" })

vim.keymap.set({ "i", "s" }, "<C-h>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.snippet.jump(-1)
  end
end, { desc = "스니펫 이전 자리" })
