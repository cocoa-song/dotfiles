# 이 설정들이 동작하려면 필요한 것 전부.
#   brew bundle --file ~/dotfiles/Brewfile

tap "laishulu/homebrew" # macism

# ── 에디터 ─────────────────────────────────────────────
brew "neovim" # 0.12+ 필수 (vim.pack · autocomplete · treesitter 동봉 파서)

# ── LSP · 포매터 (mason.nvim 대신 brew 로 일원화) ──────
brew "lua-language-server"
brew "markdown-oxide" # 마크다운 PKM — [[링크]] · 백링크 · 데일리 노트
brew "stylua"
brew "prettier"

# ── fzf-lua 백엔드 ────────────────────────────────────
brew "fzf"
brew "ripgrep" # nvim 0.12 의 grepprg 기본값이기도 하다
brew "fd"
brew "bat" # 미리보기 문법 강조

# ── macOS 전용 ────────────────────────────────────────
# 한글로 쓰다 <Esc> 를 눌러도 입력기가 한글에 남는 문제를 푼다.
# 없으면 nvim 설정이 조용히 비활성화되므로 Linux 에서도 안 깨진다.
brew "macism"

# ── 터미널 + 폰트 ─────────────────────────────────────
# 폰트가 없으면 ghostty/config 의 font-family 가 안 잡혀 글자가 깨진다.
cask "ghostty"
cask "font-jetbrains-mono-nerd-font" # 본문 + nvim 아이콘(nerd font)
cask "font-sarasa-gothic"            # 한글 (Sarasa Term K)
