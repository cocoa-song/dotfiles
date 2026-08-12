# dotfiles

기기 간에 공유하는 개인 설정.

```
nvim/          마크다운 워크벤치 (Neovim 0.12) — 자세한 건 nvim/README.md
ghostty/       터미널
zsh/           셸 — 자세한 건 아래 "zsh"
git/           공유 git 설정 + 전역 ignore — 자세한 건 아래 "git"
starship.toml  프롬프트
Brewfile       위 설정이 의존하는 외부 도구 전부
```

`~/.config/nvim`, `~/.config/ghostty`, `~/.config/starship.toml`,
`~/.config/git/ignore`, 그리고 `~/.zshrc`·`~/.zprofile`·`~/.zsh_plugins.txt` 는
이 저장소를 가리키는 심볼릭 링크다.

## 새 기기에 세팅

```bash
git clone git@github.com:hoemoon/dotfiles.git ~/dotfiles

# macism 이 서드파티 탭이라 신뢰 승인이 먼저 필요하다 (없으면 bundle 이 멈춘다)
brew tap laishulu/homebrew
brew trust laishulu/homebrew
brew bundle --file ~/dotfiles/Brewfile

# 기존 설정이 있으면 덮어쓰지 말고 밀어둔다
mv ~/.config/nvim    ~/.config/nvim.bak-$(date +%Y%m%d)
mv ~/.config/ghostty ~/.config/ghostty.bak-$(date +%Y%m%d)

ln -s ~/dotfiles/nvim    ~/.config/nvim
ln -s ~/dotfiles/ghostty ~/.config/ghostty

nvim        # vim.pack 이 nvim/nvim-pack-lock.json 대로 플러그인을 설치한다
```

### ⚠ macOS: Ghostty 는 설정 파일을 **두 곳**에서 읽는다

Ghostty 를 한 번이라도 실행한 Mac 에는 아래 파일이 자동 생성돼 있다.

```
~/Library/Application Support/com.mitchellh.ghostty/config
```

이 파일은 `~/.config/ghostty/config` 를 **대체하는 게 아니라 둘 다 로드되고,
이쪽이 나중에 읽혀 이긴다.** 그래서 심볼릭 링크만 걸면 조용히 무시된 것처럼 보인다
(실측: 링크를 건 뒤에도 `theme` 은 App Support 쪽 값이었고 `font-family` 는 양쪽이
합쳐져 4줄이 됐다). 밀어두면 된다:

```bash
mv ~/Library/Application\ Support/com.mitchellh.ghostty/config{,.bak-$(date +%Y%m%d)}
```

어느 쪽이 이겼는지는 항상 실물로 확인한다 — 설정 파일을 읽지 말고:

```bash
ghostty +show-config | grep -E '^(font-family =|theme)'
# 기대: JetBrainsMono Nerd Font Mono / Sarasa Term K / Flexoki Light
```

### zsh

```bash
mv ~/.zshrc ~/.zshrc.bak-$(date +%Y%m%d)   # 기존 설정이 있으면
ln -s ~/dotfiles/zsh/zshrc           ~/.zshrc
ln -s ~/dotfiles/zsh/zprofile        ~/.zprofile
ln -s ~/dotfiles/zsh/zsh_plugins.txt ~/.zsh_plugins.txt
ln -s ~/dotfiles/starship.toml       ~/.config/starship.toml
```

`brew bundle` 을 아직 안 돌렸어도 셸은 깨지지 않는다 — antidote·starship·fzf 는
있을 때만 부르도록 가드가 걸려 있다(플러그인과 프롬프트만 안 뜬다).

플러그인은 antidote 가 첫 셸 실행 때 `~/.zsh/plugins` 로 클론한다(목록만 추적,
실체는 추적하지 않는다). `ANTIDOTE_HOME` 을 기본값 `~/Library/Caches` 에서
옮겨둔 이유는 **OS 캐시 정리가 플러그인만 지우고 정적 번들
`~/.zsh_plugins.zsh` 는 남기기 때문**이다 — 그러면 모든 셸이 없는 경로를
source 하며 에러를 뱉는데, `.txt` 가 더 새것이 아니라서 antidote 가 스스로
복구하지도 않는다.

**`~/.zshenv` 는 여기 없다 (의도적).** App Store Connect 키 ID·개인키 경로처럼
기기에 묶인 값이 들어가고 이 저장소는 공개다 — 아래 "왜 `~/.config` 자체를
저장소로 두지 않았나" 와 같은 이유다. 새 기기에서는 손으로 만든다:

```zsh
# ~/.zshenv — 모든 zsh 가 읽는다. 출력·무거운 작업 금지.
typeset -U path PATH
path=($HOME/.local/bin $path)
export ARCHIVE_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"
export ASC_KEY_ID=... ASC_KEY_PATH=...
[[ -n $ASC_ISSUER_ID ]] || export ASC_ISSUER_ID="$(security find-generic-password -s ASC_ISSUER_ID -w 2>/dev/null)"
```

`.zshrc` 가 아니라 `.zshenv` 인 이유: `.zshrc` 는 **대화형 셸에서만** 읽혀서
`zsh -c "ship ..."` 같은 비대화형 호출에는 이 값들이 통째로 비어 있다.

### git

```bash
ln -s ~/dotfiles/git/ignore ~/.config/git/ignore
```

`~/.gitconfig` 는 **이 저장소에 없다** — `user.name`/`user.email` 과 gh 자격증명
helper 가 들어가는데 이 저장소는 공개다. 새 기기에서는 손으로 만든다:

```gitconfig
[include]
	path = ~/dotfiles/git/shared

[user]
	name = ...
	email = ...
```

`[include]` 를 **맨 위**에 두는 이유: git 은 나중에 읽은 값이 이기므로, 아래에
같은 키를 적으면 그 기기에서만 공유 설정을 덮어쓸 수 있다.

`git/shared` 는 신원과 무관한 도구·표시 설정만 담는다(delta 페이저, zdiff3
충돌 표시, colorMoved). gh 가 `gh auth setup-git` 으로 직접 관리하는 credential
블록은 옮기지 않았다 — 옮겨도 gh 가 `~/.gitconfig` 에 다시 써넣어 중복된다.

### 노트 저장소

`markdown_oxide` 는 `.moxide.toml` 이 있는 곳만 노트 루트로 잡는다(경로는 nvim 설정에
박혀 있지 않다). 새 기기에서 노트를 쓰려면 그 폴더에 `.moxide.toml` 을 둔다 —
자세한 건 [nvim/README.md](nvim/README.md) 5절.

## 왜 `~/.config` 자체를 저장소로 두지 않았나

`~/.config` 에는 `gh/`, `github-copilot/`, `configstore/` 같은 남의 도구
디렉터리가 15개 넘게 있다. 지금은 자격증명이 안 보여도 **어떤 도구가 언제
토큰을 떨굴지 통제할 수 없다.** whitelist `.gitignore` 로 막아도 `git add -f`
한 번이면 유출이다. 저장소를 `~/.config` 밖에 두면 그 위험이 구조적으로 사라진다.

## 테마는 두 곳을 같이 바꾼다

터미널과 에디터가 **같은 Flexoki 팔레트**를 쓴다. 배경 `#fffcf0` / 전경 `#100f0f`
가 정확히 일치해서 창 경계가 드러나지 않는다. 어두운 쪽으로 갈 땐 둘 다 바꾼다.

| | 밝게 | 어둡게 |
|---|---|---|
| `ghostty/config` | `theme = Flexoki Light` | `theme = Flexoki Dark` |
| `nvim/lua/config/plugins.lua` | `flexoki-light` + `background = "light"` | `flexoki-moon` + `"dark"` |

## 이력

`nvim/` 은 원래 `~/.config/nvim` 의 독립 저장소였다. `git mv` 로 하위
디렉터리에 넣었으므로 그 이전 커밋도 `git log --follow nvim/<파일>` 로 이어진다.
