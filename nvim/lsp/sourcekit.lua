-- sourcekit-lsp — Swift / Objective-C
--
-- Xcode 프로젝트(.xcworkspace/.xcodeproj)는 sourcekit-lsp 가 직접 읽지 못한다.
-- 빌드 정보를 넘겨줄 BSP 서버가 필요하고, 그 접점이 저장소 루트의
-- `buildServer.json` 이다. 보통 xcode-build-server 가 만든다:
--
--   brew install xcode-build-server
--   xcode-build-server config -workspace <이름>.xcworkspace -scheme <스킴>
--
-- 이 파일이 없으면 sourcekit-lsp 는 fallback 컴파일 인자로 돌아서 import 가
-- 전부 깨지고 같은 파일 안 심볼 말고는 정의로 점프하지 못한다.
--
-- SwiftPM 만 쓰는 저장소(Package.swift)는 BSP 없이도 동작한다.
--
-- ★ Xcode 나 Swift 툴체인이 없는 기기에서는 조용히 비활성된다.
--   Neovim 은 cmd 가 존재하지 않는 LSP 설정을 알림 없이 건너뛴다
--   (실측: 클라이언트 0개, 알림 0건, 버퍼를 더 열어도 누적 없음).
--   macism 과 같은 방식이라 Linux 에서도 설정이 깨지지 않는다.

local warned = {}
local toplevels = {}

-- 저장소 루트를 git 에게 묻고, 그 위로는 올라가지 않는다.
--
-- `vim.fs.root(path, "buildServer.json")` 을 쓰면 안 된다. 워크트리를 체크아웃
-- **안쪽**에 두는 배치(예: `<repo>/.worktrees/<name>`)에서 위로 걸어 올라가다
-- 부모 체크아웃의 buildServer.json 을 잡아버린다. 그러면 LSP 가 조용히 엉뚱한
-- 트리에 붙어서, 워크트리 파일을 편집하는데 정의는 다른 체크아웃으로 점프한다.
-- 체크아웃 루트는 "여기서 멈춘다"는 **경계**다. 프로젝트 루트가 아니다(아래 project_root).
local function git_toplevel(path)
  local dir = vim.fs.dirname(path)
  if toplevels[dir] ~= nil then
    return toplevels[dir] or nil
  end
  local r = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  local top = (r.code == 0) and vim.trim(r.stdout) or false
  toplevels[dir] = top
  return top or nil
end

-- 프로젝트 루트를 파일에서 위로 올라가며 찾되, 체크아웃 루트에서 멈춘다.
--
-- ★ "체크아웃 루트 = 프로젝트 루트" 로 두면 **모노레포에서 전부 깨진다.**
--   저장소 하나에 패키지를 여러 개 담는 배치(`<repo>/production/<앱>/Package.swift`)
--   에서는 git 루트에 Package.swift 도 buildServer.json 도 없다. 그래서 모든 Swift
--   파일이 "설정 안 됨" 으로 떨어져 fallback 인자로 돌고, import 가 깨진 채 경고만 뜬다.
--   (실측 2026-08-11: 한 저장소 안의 SwiftPM 패키지 8개가 전부 git 루트로 붙었다.)
--
--   그렇다고 `vim.fs.root` 로 무한정 올라가면 위 git_toplevel 주석의 워크트리 함정에
--   걸린다. 그래서 **아래로는 찾되 위로는 경계에서 멈춘다** — 둘 다 만족한다.
local function project_root(path, top)
  local function has(dir, file)
    return vim.fn.filereadable(dir .. "/" .. file) == 1
  end
  local function has_glob(dir, pat)
    return #vim.fn.glob(dir .. "/" .. pat, true, true) > 0
  end

  local dir = vim.fs.dirname(path)
  local xcode -- .xcworkspace/.xcodeproj 를 본 가장 가까운 디렉터리 (fallback)

  while dir do
    -- 빌드 정보가 실제로 있는 곳. 가장 가까운 것이 이긴다.
    if has(dir, "buildServer.json") or has(dir, "Package.swift") then
      return dir, true
    end
    -- 아직 설정 전인 Xcode 프로젝트. buildServer.json 이 놓일 자리가 여기다.
    if not xcode and (has_glob(dir, "*.xcworkspace") or has_glob(dir, "*.xcodeproj")) then
      xcode = dir
    end

    if dir == top then
      break -- 경계. 체크아웃 밖으로는 절대 안 나간다.
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end

  -- 설정 전 Xcode 프로젝트면 그 디렉터리를 준다 — 경고가 `xcode-build-server config` 를
  -- 실제로 돌려야 할 곳을 가리키게 된다(모노레포에서는 git 루트가 아니다).
  return xcode or top, false
end

---@type vim.lsp.Config
return {
  -- xcrun 을 거치면 `xcode-select` 가 가리키는 툴체인을 따라간다. Xcode 를 여러
  -- 개 두고 전환하는 기기에서 중요하다. xcrun 이 없는 환경(Linux)에서는 툴체인이
  -- PATH 에 올려둔 바이너리를 직접 쓴다.
  cmd = vim.fn.executable("xcrun") == 1 and { "xcrun", "sourcekit-lsp" } or { "sourcekit-lsp" },

  filetypes = { "swift", "objc", "objcpp", "c", "cpp" },

  root_dir = function(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then
      return
    end

    local top = git_toplevel(name)
    if not top then
      return
    end

    local root, configured = project_root(name, top)
    if configured then
      return on_dir(root)
    end

    -- BSP 도 SwiftPM 도 없으면 fallback 인자로 돌아 import 가 전부 깨진다.
    -- 조용히 반쯤 동작하게 두지 말고 한 번은 알린다.
    if not warned[root] then
      warned[root] = true
      vim.notify(
        ("sourcekit: no buildServer.json in %s — run `xcode-build-server config`"):format(root),
        vim.log.levels.WARN
      )
    end
    return on_dir(root)
  end,

  -- cmd_cwd 의 기본값은 root_dir 이 아니라 Neovim 의 cwd 다
  -- (:h vim.lsp.ClientConfig). xcode-build-server 는 "에디터가 연 경로" 로
  -- 컴파일 플래그 캐시를 키잉하므로 프로젝트 루트로 고정해야 캐시가 맞는다.
  -- root_dir 과 같은 규칙을 쓴다 — 체크아웃 루트로 두면 모노레포에서 buildServer.json
  -- 이 있는 디렉터리와 어긋난다.
  cmd_cwd = (function()
    local cwd = vim.uv.cwd()
    local top = git_toplevel(cwd .. "/.")
    return top and (project_root(cwd .. "/.", top)) or cwd
  end)(),

  -- 기본 get_language_id 는 Neovim 의 filetype 을 그대로 넘긴다. sourcekit-lsp 는
  -- LSP 표준 id 를 원한다.
  get_language_id = function(_, ft)
    return ({ objc = "objective-c", objcpp = "objective-cpp" })[ft] or ft
  end,
}
