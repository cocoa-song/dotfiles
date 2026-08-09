# 마크다운 워크벤치 (Neovim 0.12)

마크다운 글쓰기 + Lua(Neovim 플러그인) 개발용 설정.
2026-08-08 기준으로 생태계를 재평가해 처음부터 다시 구성.

- **Neovim**: 0.12.4 (Homebrew)
- **플러그인**: 11개 (약 28MB) — 내장 `vim.pack` 으로 관리
- **시작 시간**: 약 80ms (지연 로딩 없이 전부 즉시 로드)

```
~/.config/nvim/
├── init.lua                    진입점 — 순서대로 require
├── lua/config/
│   ├── options.lua             전역 옵션 · treesitter · 자동명령
│   ├── plugins.lua             vim.pack.add + 각 플러그인 setup
│   ├── lsp.lua                 vim.lsp.enable · LspAttach 키맵 · 진단
│   ├── keymaps.lua             전역 키맵
│   └── ime.lua                 한영 자동전환 (macOS)
├── lsp/                        서버별 설정 — vim.lsp.enable 이 자동 로드
│   ├── lua_ls.lua
│   ├── markdown_oxide.lua      노트(PKM)
│   ├── marksman.lua            (비활성 — markdown_oxide 로 대체)
│   └── harper_ls.lua           (비활성)
├── after/ftplugin/markdown.lua 마크다운 = 산문 설정
└── nvim-pack-lock.json         vim.pack 자동 생성 (git 커밋 권장)
```

---

## 1. 플러그인 없이 해결한 것 — Neovim 0.12 내장

이 설정의 핵심 판단. **2025년에 플러그인이 필요했던 4가지가 이제 코어에 있다.**

| 기능 | 내장 API | 뺀 플러그인 |
|---|---|---|
| 플러그인 관리 | `vim.pack` | lazy.nvim |
| 구문 하이라이팅 | `vim.treesitter.start()` | nvim-treesitter (+ 파서 빌드 체계 전체) |
| LSP 클라이언트 설정 | `vim.lsp.config` / `vim.lsp.enable` | nvim-lspconfig, mason-lspconfig |
| 스니펫 확장 | `vim.snippet` | LuaSnip, friendly-snippets, cmp_luasnip |

### treesitter — 파서가 동봉돼 있다

nvim 0.12 는 아래 파서를 바이너리에 포함해 배포한다:

```
markdown  markdown_inline  lua  vim  vimdoc  query  c
→ /opt/homebrew/Cellar/neovim/0.12.4/lib/nvim/parser/*.so
```

마크다운 + Lua 용도에 필요한 파서가 정확히 다 들어있어서 `nvim-treesitter` 가 전혀 필요 없다.
`lua/config/options.lua` 의 `FileType` 자동명령이 `vim.treesitter.start()` 를 호출하는 게 전부다.

> 부수 효과: nvim-treesitter 는 2026년 3월 `master`→`main` 전면 재작성을 했고
> 새 버전은 tree-sitter CLI 로 파서를 로컬 컴파일한다. 그 마이그레이션을 통째로 건너뛴다.

### LSP — `lsp/<name>.lua` 규약

`vim.lsp.enable("marksman")` 을 호출하면 Neovim 이 runtimepath 에서 `lsp/marksman.lua` 를
찾아 읽는다. 그래서 서버 설정이 `lua/` 가 아니라 최상위 `lsp/` 에 있다.

---

## 2. 플러그인 11개

### ★ render-markdown.nvim — 이 설정의 핵심

`2.3M` · MeanderingProgrammer · [repo](https://github.com/MeanderingProgrammer/render-markdown.nvim)

버퍼 안에서 마크다운을 **편집 가능한 상태 그대로** 스타일링한다.
헤딩 배경, 불릿 아이콘, 체크박스, 인용 막대, 표 정렬, 코드블록 배경.

**왜 markview.nvim 이 아닌가**: markview 는 커서가 닿은 구역의 렌더를 풀어 원문을 보여준다.
글 쓰는 동안 계속 깜빡여서 흐름이 끊긴다. render-markdown 은 extmark 기반이라 편집 중에도
스타일이 유지되고, 화면에 보이는 영역만 렌더해서 가볍다.

- 설정: `lua/config/plugins.lua`
- 토글: `<leader>tr` (원문 마크업 보기)
- `conceallevel` 을 3으로 올려 `**`, `#` 같은 기호를 숨긴다

### blink.cmp

`7.0M` · v1.10.x 고정 · [repo](https://github.com/saghen/blink.cmp)

자동완성. **nvim-cmp + 소스 6개를 1개로 대체.**
buffer / path / snippet / LSP 소스가 내장이고, 퍼지 매칭은 Rust 바이너리(첫 실행 시 자동 다운로드).

- nvim-cmp: 기본 60ms 디바운스 + 처리 중 2–50ms 끊김
- blink.cmp: 키 입력마다 0.5–4ms

**v1 계열로 고정**(`vim.version.range("1.*")`)했다. v2 는 파괴적 변경이 진행 중이다.

산문용 조정 — `preselect = false`. 자동 선택을 끄면 메뉴가 떠 있어도 Enter 가 줄바꿈으로 남는다.
이게 없으면 글 쓰다가 Enter 칠 때마다 엉뚱한 단어가 들어간다.

| 키 | 동작 |
|---|---|
| `<C-space>` | 완성 메뉴 열기 |
| `<CR>` | 선택 항목 확정 (선택 안 했으면 줄바꿈) |
| `<C-n>` / `<C-p>` | 이동 |
| `<Tab>` / `<S-Tab>` | 스니펫 자리 이동 |

### lazydev.nvim

`504K` · folke · [repo](https://github.com/folke/lazydev.nvim)

**Neovim 플러그인 작성용.** lua_ls 에게 열려 있는 파일이 실제로 `require` 한 모듈만
골라서 워크스페이스 라이브러리로 물려준다. `vim.api.*`, `vim.fn.*` 타입과 완성이 붙는다.

전신인 neodev.nvim 은 Neovim 런타임 전체를 한 번에 로드해서 lua_ls 를 느리게 만들었다.
lazydev 는 그걸 지연 로딩으로 바꾼 것. neodev 는 이제 쓰지 않는다.

blink.cmp 에 `lazydev` 소스를 Lua 파일에서만 우선순위 100으로 물려놨다 (`sources.per_filetype`).

### mason.nvim

`3.8M` · **mason-org/** · [repo](https://github.com/mason-org/mason.nvim)

LSP 서버·포매터 **바이너리 설치기**. 설정은 하지 않는다 — 그건 0.12 내장 몫.

> ⚠️ 저장소가 `williamboman/` → `mason-org/` 로 이전했다. 옛 주소는 구버전에 멈춰 있다.
> `mason-lspconfig` 도 v2 에서 역할이 축소됐고, 이 설정은 `vim.lsp.enable` 을 직접
> 호출하므로 아예 쓰지 않는다.

`:Mason` 으로 UI, `<leader>pm` 으로 열기.

### conform.nvim

`2.6M` · stevearc · [repo](https://github.com/stevearc/conform.nvim)

포매터 실행기.

- **Lua**: 저장 시 자동 포맷 (stylua)
- **마크다운**: 수동만 — `<leader>cf`

마크다운을 자동 포맷에서 뺀 이유: prettier 가 표를 정렬할 때 한글 글자 폭 계산이 어긋나
오히려 표가 깨질 수 있다. 산문에 저장할 때마다 손대는 건 위험하다.

### telescope.nvim + plenary.nvim

`4.0M` + `1.6M` · [repo](https://github.com/nvim-telescope/telescope.nvim)

파일·내용 검색. 기존 설정에서 쓰던 것이라 키맵을 그대로 유지했다.
확장(`fzf-native`, `ui-select`)은 뺐다 — 빌드 단계가 생기고 이 규모에선 체감 차이가 없다.

| 키 | 동작 |
|---|---|
| `<leader>ff` | 파일 찾기 |
| `<leader>fg` | 내용 검색 (ripgrep) |
| `<leader>fb` `<leader>fr` | 버퍼 · 최근 파일 |
| `<leader>/` | **현재 문서 안에서** 찾기 (긴 노트용) |
| `<leader>nf` `<leader>ng` | 노트 폴더 파일 찾기 · 내용 검색 |

### tokyonight.nvim / lualine.nvim / nvim-web-devicons

`3.7M` / `1.8M` / `932K` · 외형.

- 색 테마는 `tokyonight-day`(밝음). 어두운 쪽은 `plugins.lua` 에서 `-night` / `-storm`
- lualine 은 마크다운 버퍼에서 **단어 수**를 표시한다 (한글 포함)

### zen-mode.nvim

`392K` · folke · [repo](https://github.com/folke/zen-mode.nvim)

`<leader>z` — 본문을 88칸 폭으로 화면 중앙에 놓고 UI 를 숨긴다. 긴 글 쓸 때.

---

## 3. Mason 으로 설치한 외부 도구 4개

`~/.local/share/nvim/mason/bin/` 에 설치됨. 플러그인이 아니라 독립 실행 바이너리.

| 도구 | 버전 | 역할 |
|---|---|---|
| **markdown-oxide** | 0.25.12 | 마크다운 PKM LSP — `[[위키링크]]` 완성, **백링크**, 데일리 노트, 태그, 헤딩/블록 참조, `gO` 목차. 5절 참고 |
| **lua-language-server** | 3.15.0 | Lua LSP (lazydev 와 함께 동작) |
| **stylua** | 2.5.2 | Lua 포매터 — 저장 시 자동 |
| **prettier** | 3.9.6 | 마크다운 포매터 — `<leader>cf` 수동 |

추가 설치: `:MasonInstall <이름>`

### 비활성: marksman

markdown-oxide 로 대체했다. 바이너리와 `lsp/marksman.lua` 는 남겨뒀으니
`lua/config/lsp.lua` 의 `vim.lsp.enable` 에서 `"markdown_oxide"` 를 `"marksman"` 으로
바꾸면 즉시 원복된다. **둘을 동시에 켜지 말 것** — 같은 버퍼에 붙어 링크 완성 후보가 중복된다.

### 비활성: harper-ls

`lsp/harper_ls.lua` 에 설정만 넣어두고 껐다. 영문 문법·맞춤법 검사기(로컬 실행,
Grammarly 대안, Automattic 관리)인데 **한국어를 지원하지 않아** 한글 문서에서 진단이 시끄럽다.

영문 문서를 쓸 때만 켜기:
```
:MasonInstall harper-ls
:lua vim.lsp.enable("harper_ls")      -- 일회성
```
상시로 쓰려면 `lua/config/lsp.lua` 의 `vim.lsp.enable` 목록에서 주석을 푼다.

---

## 4. 시스템 의존성

| 도구 | 상태 | 용도 |
|---|---|---|
| `ripgrep` (rg) | ✅ 설치됨 | telescope 내용 검색 |
| `fd` | ✅ 설치됨 | telescope 파일 찾기 |
| `node` | ✅ v22.23.1 | prettier 실행 |
| `git` | ✅ | vim.pack 이 플러그인을 git 으로 관리 |
| **`macism`** | ✅ 설치됨 | **한영 자동전환** ↓ |

### 한영 자동전환 (macOS)

이게 없으면 한글로 쓰다 `<Esc>` 를 눌러도 입력기가 한글에 남아 `dd` 가 `ㅇㅇ` 이 되고
노멀 모드가 먹통이 된다.

```
brew tap laishulu/homebrew      # 실제 repo 는 laishulu/homebrew-homebrew
brew trust laishulu/homebrew    # 서드파티 탭이라 신뢰 승인 필요
brew install macism
```

동작: `InsertLeave` 에 현재 입력기를 기억하고 ABC 로 전환 → `InsertEnter` 에 복원.
전부 `vim.system` 비동기라 모드 전환이 느려지지 않는다.

한글 입력기 ID 는 **하드코딩하지 않고 런타임에 감지**한다.
(이 환경은 속 입력기 `com.kiding.inputmethod.sok.mode` — Apple 두벌식이 아니다)

| 명령 | 동작 |
|---|---|
| `:ImeDoctor` | 현재 입력기 · 복원 대상 · 권한 안내 |
| `:ImeRestoreToggle` | Insert 진입 시 한글 복원 끄기/켜기 |

전환이 안 되면 **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 터미널 앱에 권한을 준다.

---

## 5. 노트 (PKM)

노트 기능은 **플러그인이 아니라 LSP**(markdown-oxide)로 들어온다.
그래서 이 설정 어디에도 특정 노트 폴더 경로가 박혀 있지 않다.

### 루트 표시 파일로 저장소를 찾는다

markdown-oxide 는 버퍼가 있는 위치에서 위로 올라가며 `.moxide.toml` → `.obsidian` →
`.git` 을 찾아 그걸 노트 저장소 루트로 삼는다. 덕분에 **여러 저장소가 동시에 각각 동작**한다.

| 저장소 | 루트 표시 | 성격 |
|---|---|---|
| `~/notes` | `.moxide.toml` | 직접 쓰는 노트. git 으로 버전 관리 |
| iCloud Obsidian 볼트 | `.obsidian` | oracle 캡처 아카이브 (읽기·검색용) |

새 저장소를 만들려면 그 폴더에 빈 `.moxide.toml` 을 두면 끝이다. nvim 설정은 안 건드린다.

```
~/notes/
  .moxide.toml     daily_notes_folder = "daily"  ·  dailynote = "%Y-%m-%d"
  inbox/           정리 전 빠른 캡처
  daily/           데일리 노트
```

### 키맵

| 키 | 동작 |
|---|---|
| `<leader>nn` | 새 노트 (이름 입력 → `~/notes/<이름>.md`) |
| `<leader>nf` / `<leader>ng` | 노트 파일 찾기 / 내용 검색 |
| `<leader>nt` / `<leader>ny` | 오늘 / 어제 데일리 노트 |
| `[[` 입력 | 노트 제목 완성 (blink.cmp) |
| `gd` | 링크 따라가기 |
| **`grr`** | **백링크** — 이 노트를 참조하는 노트 목록 |
| `gO` | 헤딩 목차 |

`<leader>nt` / `<leader>ny` 는 서버가 **버퍼에 등록**하는 `:LspToday` / `:LspYesterday` 라
마크다운 버퍼에서만 동작한다. 아무 데서나 쓰려면 노트를 먼저 연다.

> **백링크 주의**: `grr` 은 커서가 **본문**에 있을 때 "이 파일로 향하는 링크"를 찾는다.
> 제목 헤딩(`# 제목`) 줄에서는 "그 헤딩에 대한 참조"를 찾기 때문에 결과가 다르다.

### 알아둘 것

- 위키링크는 한글 파일명에서도 정상 동작한다 (검증함)
- `unresolved_diagnostics` 를 켜뒀지만 깨진 `[[링크]]` 진단은 확인하지 못했다.
  기대하지 말 것 — 필요하면 `.moxide.toml` 을 조정하거나 상류에 확인이 필요하다

---

## 6. 마크다운 편집 설정

`after/ftplugin/markdown.lua`. `after/` 인 이유는 Neovim 런타임의 `ftplugin/markdown.vim` 이
`shiftwidth=4` 를 setlocal 하기 때문 — `~/.config/nvim/ftplugin/` 은 그보다 먼저 로드돼 덮어써진다.

| 설정 | 값 | 이유 |
|---|---|---|
| `wrap` + `linebreak` | on | 긴 문단을 화면에서 접되 단어 중간에서 안 자름 |
| `breakindent` | on | 접힌 줄도 들여쓰기 유지 → 리스트가 안 무너짐 |
| `textwidth` | 0 | 하드랩 금지. 한글은 어절이 길어 diff 가 지저분해진다 |
| `number` | off | 글 쓸 때 방해 |
| `shiftwidth` | 2 | prettier·Obsidian 관례 |

`j`/`k` 는 **보이는 줄** 단위로 이동(`gj`/`gk`). 단 `3j` 처럼 카운트를 붙이면 실제 줄 단위
— 그래야 상대 줄번호가 여전히 맞는다.

| 키 | 동작 |
|---|---|
| `]]` `[[` | 다음 · 이전 헤딩 |
| `<leader>ts` | 맞춤법 검사 토글 (영문) |
| `<leader>tr` | 마크다운 렌더 토글 |
| `gO` | 문서 심볼 = 목차 (markdown-oxide) |

---

## 7. 운영

```lua
:lua vim.pack.update()                      -- 전체 업데이트 (<leader>pu)
                                            --   변경 검토 후 :w 확정 / :q 취소
:lua vim.pack.update(nil, {offline = true}) -- 설치 목록·상태만 (<leader>ps)
:lua vim.pack.update({ "blink.cmp" })       -- 개별
:lua vim.pack.del({ "이름" })               -- 제거
```

- **디렉터리를 손으로 지우지 말 것** — 락파일이 어긋나 다음 시작 때 재설치된다
- 추가: `lua/config/plugins.lua` 의 `vim.pack.add` 에 한 줄 넣고 재시작
- 플러그인 위치: `~/.local/share/nvim/site/pack/core/opt/`
- `nvim-pack-lock.json` 은 이 디렉터리에 생성된다 → git 에 같이 커밋하면 다른 기기에서 동일 리비전 재현

### vim.pack 의 한계

내장 문서가 **experimental** 로 명시하고 있다(`:h vim.pack`, pack.txt:211).
이벤트/파일타입 기반 지연 로딩이 없어서 전부 시작 시 로드된다. 11개 기준 80ms 라 문제 없지만,
플러그인이 30개를 넘어가면 lazy.nvim 쪽이 유리해진다.
