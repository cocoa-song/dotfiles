-- Swift 편집 설정.
--
-- `after/` 인 이유는 markdown 쪽과 같다 — Neovim 런타임의 ftplugin 이 나중에
-- 덮어쓰지 못하게 한다.
--
-- ⚠ Neovim 은 `syntax/swift.vim`(정규식)은 동봉하지만 `indent/swift.vim` 은
--   **동봉하지 않는다.** 즉 Swift 들여쓰기는 'smartindent' 수준이 전부이고,
--   SwiftUI 의 result-builder 체인이나 trailing closure 에서는 어긋난다.
--   `==` 로 손보는 걸 각오할 것. (treesitter swift 파서를 넣어도 indent 는
--   여전히 나쁘다 — 하이라이팅만 좋아진다)

-- 전역은 2칸이지만 Swift 관례는 4칸
vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

vim.bo.commentstring = "// %s"

-- 산문용으로 켜둔 conceal 은 코드에서 글자를 지워버릴 수 있다.
vim.wo.conceallevel = 0
