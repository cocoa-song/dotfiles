-- 플러그인 — 내장 vim.pack (Neovim 0.12)
--
-- vim.pack.add() = "똑똑한 :packadd". 없으면 설치하고, 바로 로드한다.
-- 잠금은 ~/.local/share/nvim/site/pack/core/nvim-pack-lock.json 에 자동 기록.
-- 업데이트: :lua vim.pack.update()  → 변경사항 검토 후 :w 로 확정, :q 로 취소
-- 제거    : :lua vim.pack.del({ "이름" })   (디렉터리 수동 삭제 금지 — 락파일이 어긋난다)

local gh = function(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  -- 외형
  { src = gh("folke/tokyonight.nvim") },
  { src = gh("nvim-lualine/lualine.nvim") },
  { src = gh("nvim-tree/nvim-web-devicons") },

  -- ★ 마크다운 인라인 렌더링 — 이 설정의 핵심
  { src = gh("MeanderingProgrammer/render-markdown.nvim") },

  -- 터미널 인라인 이미지 (snacks 의 image 모듈 하나만 켠다)
  { src = gh("folke/snacks.nvim") },

  -- 집중 글쓰기
  { src = gh("folke/zen-mode.nvim") },

  -- 자동완성 (v1 계열 고정 — v2 는 파괴적 변경 진행 중)
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },

  -- Lua 플러그인 개발: vim API 타입 + require() 완성
  { src = gh("folke/lazydev.nvim") },

  -- LSP 서버 · 포매터 바이너리 설치기 (설정은 안 함 — 그건 0.12 내장 몫)
  { src = gh("mason-org/mason.nvim") },

  -- 포매팅
  { src = gh("stevearc/conform.nvim") },

  -- 파일/내용 검색
  { src = gh("nvim-lua/plenary.nvim") },
  { src = gh("nvim-telescope/telescope.nvim") },
})

-- ---------------------------------------------------------------- 외형
require("tokyonight").setup({
  style = "night",
  styles = { comments = { italic = true } },
})
vim.cmd.colorscheme("tokyonight-day") -- 밝은 배경 선호 시 -day, 어두운 쪽은 -night / -storm

require("nvim-web-devicons").setup({})

require("lualine").setup({
  options = {
    theme = "tokyonight",
    section_separators = "",
    component_separators = "|",
  },
  sections = {
    lualine_x = {
      -- 마크다운에서 단어 수를 보여준다 (한글 포함)
      function()
        if vim.bo.filetype ~= "markdown" then
          return ""
        end
        local wc = vim.fn.wordcount()
        return (wc.visual_words or wc.words) .. " words"
      end,
      "filetype",
    },
  },
})

-- ------------------------------------------------- ★ 마크다운 렌더링
-- extmark 기반이라 편집 중에도 스타일이 유지된다.
-- (경쟁 플러그인 markview.nvim 은 커서가 닿으면 렌더가 풀려 글 흐름이 끊긴다)
require("render-markdown").setup({
  completions = { blink = { enabled = true } },
  heading = {
    sign = false,
    icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    width = "block",
    left_pad = 0,
    right_pad = 2,
  },
  code = {
    sign = false,
    width = "block",
    right_pad = 2,
    left_pad = 1,
  },
  bullet = { icons = { "•", "◦", "▸", "▹" } },
  checkbox = {
    unchecked = { icon = "󰄱 " },
    checked = { icon = "󰱒 ", scope_highlight = "@markup.strikethrough" },
  },
  quote = { icon = "▍" },
  pipe_table = { preset = "round" },
  link = { wiki = { icon = "󰌷 ", highlight = "RenderMarkdownWikiLink" } },
})

-- ------------------------------------------------------- 인라인 이미지
-- snacks.nvim 은 모듈 모음이다. image 하나만 켜고 나머지는 전부 끈다.
-- (setup 에 안 적은 모듈은 기본적으로 비활성이라 별도 조치 불필요)
--
-- 요구사항
--   · 터미널이 Kitty 그래픽 프로토콜 지원 — Ghostty ✅ (kitty·wezterm 도 가능)
--   · ImageMagick — PNG 외 형식 변환용. 이 볼트는 jpg 2321 / webp 19 / gif 9 라 필수
require("snacks").setup({
  image = {
    enabled = true,
    doc = {
      enabled = true, -- 마크다운 문서 안 이미지 표시
      inline = true, -- 텍스트 흐름 안에 바로 렌더 (false 면 별도 창)
      float = true, -- 인라인이 불가능한 상황에선 떠있는 창으로
      max_width = 60,
      max_height = 20,
    },
    -- ![[해시.png]] 형태의 Obsidian 임베드도 인식하도록
    -- 첨부 폴더를 검색 경로에 넣는다
    resolve = function(path, src)
      -- src 가 확장자만 있는 위키 임베드면 볼트 attachments 에서 찾는다
      if src:match("^[^/]+%.%w+$") then
        local vault = vim.env.HOME .. "/Library/Mobile Documents/iCloud~md~obsidian/Documents"
        local candidate = vault .. "/attachments/" .. src
        if vim.uv.fs_stat(candidate) then
          return candidate
        end
      end
    end,
  },
})

-- ------------------------------------------------------------ 자동완성
require("blink.cmp").setup({
  keymap = {
    preset = "default", -- <C-space> 열기 · <C-y> 확정 · <C-e> 닫기 · <C-n>/<C-p> 이동
    ["<CR>"] = { "accept", "fallback" },
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },
  appearance = { nerd_font_variant = "mono" },
  completion = {
    -- 산문에선 자동 선택이 방해가 된다. Enter 가 줄바꿈으로 남도록 preselect 끔.
    list = { selection = { preselect = false, auto_insert = true } },
    documentation = { auto_show = true, auto_show_delay_ms = 250 },
    menu = { border = "rounded" },
  },
  signature = { enabled = true },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    per_filetype = {
      lua = { "lazydev", "lsp", "path", "snippets", "buffer" },
    },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

-- --------------------------------------------- Lua 플러그인 개발 지원
-- lua_ls 에 Neovim 런타임 타입을 lazy 하게 물려준다 (neodev.nvim 대체).
require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
})

-- ------------------------------------------------------ 바이너리 설치
require("mason").setup({
  ui = { border = "rounded" },
})

-- ------------------------------------------------------------ 포매팅
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    markdown = { "prettier" },
  },
  -- 저장 시 자동 포맷은 Lua 만. 마크다운은 <leader>cf 로 수동.
  -- (prettier 가 표를 정렬할 때 한글 폭 계산이 어긋나 오히려 깨지는 경우가 있어
  --  산문에 자동 적용은 위험하다)
  format_on_save = function(bufnr)
    if vim.bo[bufnr].filetype ~= "lua" then
      return nil
    end
    return { timeout_ms = 1500, lsp_format = "fallback" }
  end,
})

-- -------------------------------------------------------------- 검색
local telescope = require("telescope")
local actions = require("telescope.actions")

telescope.setup({
  defaults = {
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<Esc>"] = actions.close,
      },
    },
    file_ignore_patterns = { "%.git/", "node_modules/", "%.obsidian/", "build/", "dist/" },
    vimgrep_arguments = {
      "rg", "--color=never", "--no-heading", "--with-filename",
      "--line-number", "--column", "--smart-case",
    },
  },
  pickers = {
    find_files = { find_command = { "fd", "--type", "f", "--strip-cwd-prefix" } },
    buffers = { sort_lastused = true, ignore_current_buffer = true },
  },
})

-- ------------------------------------------------------- 집중 글쓰기
require("zen-mode").setup({
  window = {
    width = 88, -- 한 줄에 들어갈 글자 수. 한글 기준 44자 남짓
    options = {
      number = false,
      relativenumber = false, -- 집중 모드에선 줄번호를 아예 숨긴다
      cursorline = false,
      signcolumn = "no",
      foldcolumn = "0",
      list = false,
    },
  },
  plugins = {
    options = { laststatus = 0 },
  },
})
