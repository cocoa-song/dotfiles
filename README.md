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
brew bundle --file ~/dotfiles/Brewfile

ln -s ~/dotfiles/nvim    ~/.config/nvim
ln -s ~/dotfiles/ghostty ~/.config/ghostty

nvim        # vim.pack 이 nvim/nvim-pack-lock.json 대로 플러그인을 설치한다
```

`macism` 은 서드파티 탭이라 brew 가 신뢰 승인을 먼저 요구할 수 있다:

```bash
brew tap   laishulu/homebrew
brew trust laishulu/homebrew
```

### ⚠ macOS 에서 ghostty 는 설정을 **두 곳에서 읽어 합친다**

`~/.config/ghostty/config` 만 링크해도, 이미 있던
`~/Library/Application Support/com.mitchellh.ghostty/config` 가 **나중에 로드돼 이긴다.**
실측(2026-08-11): 링크 직후 `ghostty +show-config` 가

- `font-family` 에 링크본 2개 + 옛 파일 2개, 합쳐서 4개를 쌓고
- `macos-option-as-alt` 을 링크본의 `left` 가 아니라 옛 파일의 `true` 로 보고

했다. 옛 파일을 치워야 링크한 설정만 적용된다:

```bash
mv ~/Library/Application\ Support/com.mitchellh.ghostty/config{,.bak}
ghostty +show-config | grep -E 'font-family =|theme|macos-option'   # 확인
```

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
