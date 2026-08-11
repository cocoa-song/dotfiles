# dotfiles

기기 간에 공유하는 개인 설정.

```
nvim/       마크다운 워크벤치 (Neovim 0.12) — 자세한 건 nvim/README.md
ghostty/    터미널
Brewfile    위 설정이 의존하는 외부 도구 전부
```

`~/.config/nvim` 과 `~/.config/ghostty` 는 이 저장소를 가리키는 심볼릭 링크다.

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
