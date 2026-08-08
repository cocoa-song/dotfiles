-- 한글 입력기 자동 전환 (macOS)
--
-- 문제: 한글로 쓰다가 <Esc> 를 눌러도 입력기는 한글에 남아 있다.
-- 그래서 `dd` 가 `ㅇㅇ` 이 되고 노멀 모드 명령이 전부 먹통이 된다.
-- macOS 한국어 사용자가 nvim 을 포기하는 1번 이유.
--
-- 해결: Insert 를 벗어날 때 영문(ABC)으로 강제 전환하고, 다시 들어갈 때 복원.
--
-- 백엔드: macism  (brew install)
--     brew tap laishulu/homebrew
--     brew install macism
--   ※ 탭 이름이 `laishulu/homebrew` 다 (실제 repo 는 laishulu/homebrew-homebrew).
--   ※ 서드파티 탭이라 brew 가 `brew trust laishulu/homebrew` 를 먼저 요구한다.
--
-- 이 파일은 macism 이 없으면 조용히 비활성화된다. 상태 확인은 :ImeDoctor

local M = {}

local ENGLISH = "com.apple.keylayout.ABC"

-- 한글 입력기 ID 는 사람마다 다르다. 하드코딩하지 않고 런타임에 감지한다.
--   Apple 두벌식 : com.apple.inputmethod.Korean.2SetKorean
--   속 입력기    : com.kiding.inputmethod.sok.mode
--   구름 입력기  : org.youknowone.inputmethod.Gureum.han2
-- 이 환경에서는 속(SokIM)이 감지된다.
M.korean = nil

local bin = vim.fn.exepath("macism")

local function current(cb)
  vim.system({ bin }, { text = true }, function(out)
    cb(vim.trim(out.stdout or ""))
  end)
end

vim.api.nvim_create_user_command("ImeDoctor", function()
  if bin == "" then
    vim.notify(table.concat({
      "macism 없음 → 한영 자동전환 꺼짐",
      "",
      "설치:",
      "  brew tap laishulu/homebrew",
      "  brew trust laishulu/homebrew",
      "  brew install macism",
    }, "\n"), vim.log.levels.WARN)
    return
  end
  current(function(cur)
    vim.schedule(function()
      vim.notify(table.concat({
        "macism   : " .. bin,
        "현재     : " .. (cur ~= "" and cur or "(응답 없음)"),
        "영문 소스: " .. ENGLISH,
        "복원 대상: " .. (M.korean or "(아직 감지 안 됨 — 한글로 한 번 입력해보세요)"),
        "",
        "전환이 안 되면: 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용 에서",
        "터미널 앱에 권한을 주세요. macism 은 GUI 세션에 붙어야 동작합니다.",
      }, "\n"))
    end)
  end)
end, { desc = "한영 자동전환 상태 점검" })

if bin == "" then
  return M -- 바이너리 없으면 아무 것도 안 함. :ImeDoctor 로 안내.
end

-- 시작 시 현재 입력기를 한 번 읽어둔다 (한글이면 그걸 복원 대상으로)
current(function(cur)
  if cur ~= "" and cur ~= ENGLISH then
    M.korean = cur
  end
end)

local group = vim.api.nvim_create_augroup("korean_ime", { clear = true })

-- Insert 이탈: 지금 쓰던 입력기를 기억하고 영문으로
vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost" }, {
  group = group,
  callback = function()
    -- 비동기 — 모드 전환이 입력기 프로세스 때문에 버벅이지 않게
    current(function(cur)
      if cur == "" or cur == ENGLISH then
        return
      end
      M.korean = cur
      vim.system({ bin, ENGLISH })
    end)
  end,
})

-- Insert 진입: 직전 한글 입력기 복원
vim.api.nvim_create_autocmd("InsertEnter", {
  group = group,
  callback = function()
    if M.restore ~= false and M.korean then
      vim.system({ bin, M.korean })
    end
  end,
})

-- 복원이 거슬릴 때(항상 영문으로 입력을 시작하고 싶을 때)
vim.api.nvim_create_user_command("ImeRestoreToggle", function()
  M.restore = (M.restore == false)
  vim.notify("Insert 진입 시 한글 복원: " .. (M.restore ~= false and "켬" or "끔"))
end, { desc = "Insert 진입 시 한글 복원 토글" })

return M
