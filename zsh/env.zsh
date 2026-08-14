# 공유 환경변수. ~/.zshenv 가 source 한다 — 모든 zsh 가 읽는다
# (스크립트·`zsh -c`·비대화형 포함). 출력 금지, 무거운 작업 금지.
#
# 기기에 묶인 값(App Store Connect 자격증명 등)은 여기 두지 않는다.
# 그건 ~/.zshenv 의 이 줄 아래에 직접 적는다 — 이 저장소는 공개다.

# PATH — 중복 자동 제거. ~/.local/bin 이 앞서야 ship·uia·tiny-press 가
# brew 사본보다 먼저 잡힌다. 로그인 셸에서는 profile.zsh 가 한 번 더 확정한다.
typeset -U path PATH
path=($HOME/.local/bin $path)

# scribe 트랜스크립트 + `oracle export` 공용 vault 루트
export ARCHIVE_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"
