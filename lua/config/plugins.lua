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
  { src = gh("ibhagwan/fzf-lua") },
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
-- fzf-lua — 목록을 Lua 가 들고 있지 않고 fzf 프로세스가 처리한다.
-- telescope + plenary(2개, 5.6MB) 를 1개로 줄이면서 큰 저장소에서 더 빠르다.
-- 외부 의존: fzf(brew) · fd · rg · bat(미리보기 문법 강조)
require("fzf-lua").setup({
  "default-title", -- 각 창에 제목 표시
  winopts = {
    height = 0.85,
    width = 0.85,
    preview = {
      layout = "flex", -- 창이 좁으면 자동으로 위아래 배치
      scrollbar = false,
    },
  },
  keymap = {
    builtin = {
      ["<C-u>"] = "preview-page-up",
      ["<C-d>"] = "preview-page-down",
    },
    fzf = {
      -- telescope 에서 쓰던 이동 키를 그대로 유지
      ["ctrl-j"] = "down",
      ["ctrl-k"] = "up",
      ["ctrl-q"] = "select-all+accept", -- 전체를 quickfix 로
    },
  },
  files = {
    cmd = "fd --type f --strip-cwd-prefix --hidden --exclude .git",
  },
  grep = {
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden -g '!.git'",
  },
  -- 노트 검색에서 Obsidian 설정 폴더가 섞이지 않게
  file_ignore_patterns = { "%.obsidian/", "node_modules/", "/build/", "/dist/" },
})

-- ------------------------------------------------------- 집중 글쓰기
require("zen-mode").setup({
  window = {
    width = 88, -- 한 줄에 들어갈 글자 수. 한글 기준 44자 남짓
    options = {
      number = false,
      relativenumber = true,
      cursorline = false,
      signcolumn = "no",
    },
  },
  plugins = {
    options = { laststatus = 0 },
  },
})
