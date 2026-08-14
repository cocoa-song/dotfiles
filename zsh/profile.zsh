# 공유 로그인 셸 설정. ~/.zprofile 이 source 한다.
#
# 설치기(OrbStack·nvm·conda 등)가 ~/.zprofile 에 덧붙이는 줄은 여기 두지 않는다.
# 그건 그 기기의 ~/.zprofile 에 남는다 — 그러라고 참조 방식을 쓴다.

eval "$(brew shellenv)"

# brew shellenv 가 PATH 맨 앞에 끼어들므로 ~/.local/bin 우선순위를 되돌린다.
# typeset -U(env.zsh) 덕에 추가가 아니라 이동만 일어난다.
path=($HOME/.local/bin $path)
