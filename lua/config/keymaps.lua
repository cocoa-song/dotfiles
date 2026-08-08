local map = vim.keymap.set

-- ------------------------------------------------------------- 기본
map("n", "<leader>w", "<cmd>write<CR>", { desc = "저장" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "닫기" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "검색 강조 끄기" })

-- 검색 결과가 항상 화면 중앙에 오게
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- 비주얼 모드에서 블록 이동
map("x", "J", ":m '>+1<CR>gv=gv", { desc = "선택 영역 아래로" })
map("x", "K", ":m '<-2<CR>gv=gv", { desc = "선택 영역 위로" })

-- ----------------------------------------------------------- 찾기
local t = require("telescope.builtin")
map("n", "<leader>ff", t.find_files, { desc = "파일 찾기" })
map("n", "<leader>fg", t.live_grep, { desc = "내용 검색" })
map("n", "<leader>fb", t.buffers, { desc = "버퍼" })
map("n", "<leader>fr", t.oldfiles, { desc = "최근 파일" })
map("n", "<leader>fh", t.help_tags, { desc = "도움말" })
map("n", "<leader>fs", t.grep_string, { desc = "커서 아래 단어 검색" })
map("n", "<leader>fd", t.diagnostics, { desc = "진단 목록" })
-- 현재 파일 안에서 찾기 (긴 노트에서 유용)
map("n", "<leader>/", t.current_buffer_fuzzy_find, { desc = "이 문서 안에서 찾기" })

-- --------------------------------------------------------- 노트 폴더
-- obsidian.nvim 없이, 노트 디렉터리로 바로 가는 텔레스코프 단축키만.
-- (필요 없으면 이 블록만 지우면 된다)
local NOTES = vim.env.HOME .. "/Library/Mobile Documents/iCloud~md~obsidian/Documents"

map("n", "<leader>nf", function()
  t.find_files({ cwd = NOTES, prompt_title = "노트 파일" })
end, { desc = "노트 파일 찾기" })

map("n", "<leader>ng", function()
  t.live_grep({ cwd = NOTES, prompt_title = "노트 검색" })
end, { desc = "노트 내용 검색" })

-- --------------------------------------------------------- 글쓰기
map("n", "<leader>z", function()
  Snacks.zen()
end, { desc = "집중 모드" })
map("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "포맷" })

-- ------------------------------------------------------------ 관리
map("n", "<leader>pu", function()
  vim.pack.update()
end, { desc = "플러그인 업데이트" })
map("n", "<leader>ps", function()
  vim.pack.update(nil, { offline = true })
end, { desc = "플러그인 목록/상태" })
map("n", "<leader>pm", "<cmd>Mason<CR>", { desc = "Mason (LSP·포매터 설치)" })
