-- Lua — Neovim 플러그인 작성용. (바이너리 = brew)
--
-- 예전엔 lazydev.nvim 이 "열린 파일이 실제로 require 한 모듈만" 골라 동적으로
-- 물려줬다. 그걸 빼고 라이브러리를 정적으로 박는다.
--   · 완성 결과는 동일 (require("...") 후보 80개, vim.api 타입 모두 정상 — 실측)
--   · 대가는 lua_ls 메모리 357MB → 562MB
-- 되돌리려면 folke/lazydev.nvim 을 plugins.lua 에 넣고 아래 library 를 지운다.
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        -- Neovim 런타임 + 설치된 플러그인들. glob 이라 플러그인이 늘고 줄어도 따라간다.
        library = vim.list_extend({
          vim.env.VIMRUNTIME .. "/lua",
          "${3rd}/luv/library",
        }, vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/core/opt/*/lua", true, true)),
      },
      telemetry = { enable = false },
      hint = { enable = true, arrayIndex = "Disable" },
      format = { enable = false }, -- 포맷은 stylua(conform) 담당
      diagnostics = { unusedLocalExclude = { "_*" } },
    },
  },
}
