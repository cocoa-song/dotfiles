local o = vim.o

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- 화면
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.termguicolors = true
o.scrolloff = 5
o.splitright = true
o.splitbelow = true
o.winborder = "rounded" -- 0.12: 떠있는 창 전부에 테두리

-- 입력
o.mouse = "a"
o.clipboard = "unnamedplus"
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true

-- 검색
o.ignorecase = true
o.smartcase = true
o.inccommand = "split" -- :s 결과 실시간 미리보기

-- 노트는 되돌리기가 생명. 영구 undo 로 어제 지운 문단도 복구된다.
o.undofile = true
o.swapfile = false
o.updatetime = 250

-- render-markdown 이 마크업 기호(**, #, - [ ])를 숨기려면 필요
o.conceallevel = 2
o.concealcursor = "" -- 커서가 있는 줄은 원문 노출 → 편집 가능

-- 0.12 내장 treesitter 파서로 하이라이팅.
-- markdown / markdown_inline / lua / vim / vimdoc / query / c 는 nvim 에 동봉돼 있어
-- nvim-treesitter 플러그인이 전혀 필요 없다.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ts_highlight", { clear = true }),
  pattern = { "markdown", "lua", "vim", "help", "query", "c" },
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- 복사한 영역 잠깐 하이라이트
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- 파일을 다시 열면 마지막 커서 위치로 (긴 노트에서 유용)
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("last_position", { clear = true }),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
