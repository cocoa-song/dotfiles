-- 마크다운은 코드가 아니라 산문이다. 전역 설정을 여기서 뒤집는다.
--
-- `after/ftplugin` 에 있는 이유: Neovim 런타임의 ftplugin/markdown.vim 이
-- `setlocal expandtab tabstop=4 softtabstop=4 shiftwidth=4` 를 실행한다.
-- ~/.config/nvim/ftplugin 은 그보다 *먼저* 로드돼 덮어써진다.
-- after/ 는 마지막에 로드되므로 여기 쓴 값이 최종적으로 이긴다.
local o = vim.opt_local

-- 리스트 들여쓰기 2칸 (prettier · Obsidian 관례)
o.tabstop = 2
o.softtabstop = 2
o.shiftwidth = 2
o.expandtab = true

-- 줄바꿈: 하드랩(textwidth) 금지, 화면에서만 접는다.
-- 한글은 어절 단위가 길어서 하드랩을 걸면 diff 도 지저분해지고 재편집이 괴롭다.
o.wrap = true
o.linebreak = true -- 단어 중간에서 자르지 않음
o.breakindent = true -- 접힌 줄도 들여쓰기 유지 → 리스트가 안 무너짐
o.showbreak = "↳ "
o.textwidth = 0
o.colorcolumn = ""

-- 글 쓸 땐 줄번호가 방해된다 (이동은 검색·헤딩 점프로)
o.number = false
o.relativenumber = false

o.conceallevel = 2
o.spelllang = "en_us" -- 한글은 nvim 스펠 사전이 없어 영문만. <leader>ts 로 토글
o.spell = false

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc })
end

-- 접힌 줄 위에서는 j/k 가 "보이는 줄" 단위로 움직여야 자연스럽다.
-- count 를 붙였을 때(3j)는 실제 줄 단위 유지 — 그래야 상대줄번호가 여전히 맞는다.
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { buffer = true, expr = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { buffer = true, expr = true })
map({ "n", "x" }, "0", "g0", "줄 시작(보이는 줄)")
map({ "n", "x" }, "$", "g$", "줄 끝(보이는 줄)")

-- 헤딩 사이 이동
map("n", "]]", "/^#\\+ <CR>:nohlsearch<CR>", "다음 헤딩")
map("n", "[[", "?^#\\+ <CR>:nohlsearch<CR>", "이전 헤딩")

-- 감싸기 — 마크다운 버퍼에서만. `ysiw*` 를 두 번 쳐도 `**굵게**` 가 되지 않아서
-- (두 번째가 이미 붙은 `*` 를 단어로 잡는다) 전용 대상을 만든다.
--   ysiwb → **굵게**   ysiwi → *기울임*   ysiwc → `코드`   ysiwl → [링크]()
--   비주얼 선택 후 Sb / Si / Sc / Sl 도 동일
local ok, surround = pcall(require, "nvim-surround")
if ok then
  -- `%b` 는 서로 다른 두 문자에만 쓸 수 있어서(`%b()`) `**` 같은 같은-문자
  -- 구분자에는 못 쓴다. 비탐욕 매칭(`.-`)으로 직접 쓴다.
  local pair = function(l, r)
    return {
      add = { { l }, { r } },
      find = vim.pesc(l) .. ".-" .. vim.pesc(r),
      delete = "^(" .. vim.pesc(l) .. ")().-(" .. vim.pesc(r) .. ")()$",
    }
  end
  surround.buffer_setup({
    -- `b` 는 기본 별칭이 `()` 다. get_alias 는 값이 문자열일 때만 별칭으로 쓰므로
    -- false 를 주면 별칭을 지나쳐 아래 surrounds["b"] 가 잡힌다.
    aliases = { ["b"] = false },
    surrounds = {
      ["b"] = pair("**", "**"),
      ["i"] = pair("*", "*"),
      ["c"] = pair("`", "`"),
      ["l"] = { -- [단어]() — 링크 주소는 직접 채운다
        add = function()
          return { { "[" }, { "]()" } }
        end,
      },
    },
  })
end

-- 맞춤법 토글 (영문 문서 쓸 때)
map("n", "<leader>ts", function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
  vim.notify("맞춤법 검사: " .. (vim.opt_local.spell:get() and "켬" or "끔"))
end, "맞춤법 토글")

-- 렌더링 토글 (원문 마크업을 그대로 보고 싶을 때)
map("n", "<leader>tr", "<cmd>RenderMarkdown toggle<CR>", "마크다운 렌더 토글")
