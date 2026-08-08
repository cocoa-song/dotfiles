-- Lua — Neovim 플러그인 작성용.
-- vim 전역·API 타입은 lazydev.nvim 이 열린 파일에 맞춰 동적으로 주입하므로
-- 여기서 workspace.library 를 통째로 박지 않는다 (그게 lua_ls 를 느리게 만드는 원인).
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      hint = { enable = true, arrayIndex = "Disable" },
      format = { enable = false }, -- 포맷은 stylua(conform) 담당
      diagnostics = { unusedLocalExclude = { "_*" } },
    },
  },
}
