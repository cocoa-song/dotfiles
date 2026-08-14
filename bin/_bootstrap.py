"""Homebrew python 위의 venv 로 자기 자신을 다시 띄운다.

두 스크립트(setup·sync)가 공유한다. 표준 라이브러리만 쓰고, 시스템 python
3.9 에서도 돌아야 한다 — 이 파일이 바로 그 3.9 를 벗어나게 해주는 코드다.

왜 시스템 python 을 안 쓰나: CLT 의 3.9.6 은 Apple 이 언제 바꿀지 모르는
부산물이고 이미 EOL 이다. Homebrew python 을 강제하면 두 기기가 같은 버전을
쓰고, 최신 문법과 pip 패키지를 마음대로 쓸 수 있다.
"""

import os
import subprocess
import sys
from pathlib import Path

DOTFILES = Path(__file__).resolve().parent.parent
VENV = DOTFILES / ".venv"
VENV_PY = VENV / "bin/python"
REQUIREMENTS = DOTFILES / "bin/requirements.txt"


def _brew_prefix():
    for p in ("/opt/homebrew", "/usr/local"):
        if (Path(p) / "bin/brew").is_file():
            return Path(p)
    return None


def _brew_python():
    """Homebrew 가 제공하는 python3. 없으면 None."""
    prefix = _brew_prefix()
    if prefix is None:
        return None
    py = prefix / "bin/python3"
    return py if py.is_file() else None


def running_in_venv() -> bool:
    # sys.executable 로 비교하면 안 된다 — venv 의 bin/python 은 베이스
    # 인터프리터로의 심링크라 resolve() 하면 둘이 같아져서, venv 밖인데도
    # 안이라고 판정한다(실측). sys.prefix 는 venv 안에서만 venv 를 가리킨다.
    return Path(sys.prefix) == VENV


def ensure(create: bool, on_progress=None) -> None:
    """venv 아래에서 돌고 있지 않으면 그리로 다시 띄운다.

    create=False (sync) 면 venv 가 없을 때 안내만 하고 멈춘다 — 없는 걸
    말없이 만들면 '갱신' 명령이 몇십 초씩 걸리는 이유를 알 수 없게 된다.
    """
    if running_in_venv():
        return

    if not VENV_PY.is_file():
        if not create:
            sys.exit(
                "python 환경이 아직 없다. 먼저 한 번 실행할 것:\n"
                "    {}/bin/setup".format(DOTFILES)
            )
        _create(on_progress)

    # 인자를 그대로 넘겨 다시 실행한다. 여기서부터는 brew python + rich.
    os.execv(str(VENV_PY), [str(VENV_PY), sys.argv[0]] + sys.argv[1:])


def _create(on_progress) -> None:
    def say(msg):
        if on_progress:
            on_progress(msg)

    prefix = _brew_prefix()
    if prefix is None:
        sys.exit(
            "Homebrew 가 없다. 먼저 설치할 것:\n"
            "    /bin/bash -c \"$(curl -fsSL "
            "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        )

    py = _brew_python()
    if py is None:
        # brew 는 있는데 python 이 없다 — 시스템 python 으로 물러서지 않고 깐다.
        say("Homebrew python 을 설치한다")
        env = dict(os.environ, HOMEBREW_NO_AUTO_UPDATE="1")
        r = subprocess.run([str(prefix / "bin/brew"), "install", "python"],
                           env=env, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, text=True)
        py = _brew_python()
        if py is None:
            sys.exit("Homebrew python 설치 실패:\n" + r.stdout)

    say("python 환경을 만든다 (처음 한 번, 10초쯤)")
    r = subprocess.run([str(py), "-m", "venv", str(VENV)],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode != 0:
        sys.exit("venv 생성 실패:\n" + r.stdout)

    r = subprocess.run(
        [str(VENV / "bin/pip"), "install", "--quiet", "--disable-pip-version-check",
         "-r", str(REQUIREMENTS)],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if r.returncode != 0:
        sys.exit("의존성 설치 실패:\n" + r.stdout)
