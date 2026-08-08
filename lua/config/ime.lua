-- 한글 입력기 자동 전환 (macOS)
--
-- 문제: 한글로 쓰다가 <Esc> 를 눌러도 입력기가 한글에 남아 `dd` 가 `ㅇㅇ` 이 된다.
-- 해결: Insert 를 벗어날 때 영문(ABC)으로, 다시 들어갈 때 직전 한글 입력기로.
--
-- ⚠ 전제 — 속 입력기(SokIM) 사용자는 이걸 먼저 꺼야 한다:
--    메뉴바 속 입력기(한/A) 아이콘 → "ABC 입력기 제한" 체크 해제
--    켜져 있으면 SokIM 이 ABC 전환을 ~100ms 뒤 되돌리므로(실측 확인)
--    이 파일을 어떻게 고쳐도 노멀 모드가 영문이 되지 않는다.
--    확인 방법: :ImeDoctor  ← 실제로 전환해보고 되돌려지는지 검사한다
--
-- 백엔드: macism  (brew tap laishulu/homebrew → brew trust → brew install macism)

local M = {}

local ENGLISH = "com.apple.keylayout.ABC"
local bin = vim.fn.exepath("macism")

M.korean = nil -- 복원할 한글 입력기 ID (런타임 감지 — 하드코딩하지 않는다)
M.restore = true -- Insert 진입 시 한글 복원 여부

-- ---------------------------------------------------------------------------
-- 단일 슬롯 큐
--
-- 예전 구현은 InsertLeave 에서 "현재 입력기 읽기 → 그 결과로 전환" 2단 비동기라
-- 빠르게 i<Esc> 를 반복하면 콜백 순서가 뒤집혔다. 실측 로그:
--     [ 5.9ms] InsertEnter  → 한글 복원
--     [48.7ms] InsertLeave 의 읽기 완료 → 이제서야 영문 전환   ← 역전
-- 아래 구조는 "마지막으로 원하는 상태" 하나만 남겨 합치므로 역전이 불가능하다.
-- ---------------------------------------------------------------------------
local want, busy = nil, false

local function pump()
  if busy or want == nil then
    return
  end
  local target = want
  want = nil
  busy = true
  vim.system({ bin, target }, { text = true }, function()
    busy = false
    vim.schedule(pump)
  end)
end

-- 항상 큐에 넣는다. "이미 그 상태일 것"이라는 추측으로 건너뛰지 않는다 —
-- SokIM 이나 사용자가 밖에서 입력기를 바꿔놨을 수 있기 때문.
local function set(target)
  if not target or target == "" then
    return
  end
  want = target
  pump()
end

-- 모드가 바뀔 때마다 세대를 올린다. 늦게 도착한 조회 콜백은 버린다.
local gen = 0

local function learn(cb)
  local g = gen
  vim.system({ bin }, { text = true }, function(o)
    if g ~= gen then
      return
    end
    local cur = vim.trim(o.stdout or "")
    if cur ~= "" and cur ~= ENGLISH then
      M.korean = cur
    end
    if cb then
      vim.schedule(function()
        if g == gen then
          cb()
        end
      end)
    end
  end)
end

-- ---------------------------------------------------------------------------
-- 진단
-- ---------------------------------------------------------------------------
vim.api.nvim_create_user_command("ImeDoctor", function()
  if bin == "" then
    vim.notify(
      table.concat({
        "macism 없음 → 한영 자동전환 꺼짐",
        "",
        "  brew tap laishulu/homebrew",
        "  brew trust laishulu/homebrew",
        "  brew install macism",
      }, "\n"),
      vim.log.levels.WARN
    )
    return
  end
  -- 말로 안내하지 말고 실제로 전환해보고, 되돌아오는지까지 확인한다.
  vim.system({ bin }, { text = true }, function(o0)
    local before = vim.trim(o0.stdout or "")
    vim.system({ bin, ENGLISH }, { text = true }, function()
      vim.defer_fn(function()
        vim.system({ bin }, { text = true }, function(o1)
          local after = vim.trim(o1.stdout or "")
          vim.system({ bin, before }, { text = true }, function()
            local reverted = after ~= ENGLISH
            vim.schedule(function()
              vim.notify(
                table.concat({
                  "macism   : " .. bin,
                  "시작 상태: " .. before,
                  "영문 전환 800ms 후: " .. after,
                  "복원 대상: " .. (M.korean or "(미감지)"),
                  "",
                  reverted
                      and ("⛔ 영문 전환이 되돌려졌습니다.\n"
                        .. '속 입력기 메뉴바(한/A) → "ABC 입력기 제한" 체크를 해제하세요.\n'
                        .. "이게 켜져 있으면 설정으로는 고칠 수 없습니다.")
                    or "✅ 영문 전환이 유지됩니다.",
                }, "\n"),
                reverted and vim.log.levels.ERROR or vim.log.levels.INFO
              )
            end)
          end)
        end)
      end, 800)
    end)
  end)
end, { desc = "한영 자동전환 상태 점검 (실제 전환 테스트)" })

vim.api.nvim_create_user_command("ImeRestoreToggle", function()
  M.restore = not M.restore
  vim.notify("Insert 진입 시 한글 복원: " .. (M.restore and "켬" or "끔"))
end, { desc = "Insert 진입 시 한글 복원 토글" })

vim.api.nvim_create_user_command("ImeSync", function()
  learn(function()
    vim.notify("복원 대상: " .. (M.korean or "(미감지)"))
  end)
end, { desc = "지금 쓰는 한글 입력기를 복원 대상으로 재감지" })

if bin == "" then
  return M
end

learn(nil)

local group = vim.api.nvim_create_augroup("korean_ime", { clear = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost" }, {
  group = group,
  callback = function()
    gen = gen + 1
    if M.korean == nil then
      learn(function()
        set(ENGLISH)
      end) -- 최초 1회만 조회
    else
      set(ENGLISH) -- 핫 패스: 프로세스 1개, 조회 없음
    end
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  group = group,
  callback = function()
    gen = gen + 1
    if M.restore and M.korean then
      set(M.korean)
    end
  end,
})

return M
