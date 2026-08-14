"""setup·sync 가 공유하는 출력 계층.

원칙 셋:

1. **한 단계 = 한 줄.** 잘 된 건 요약 한 줄로 끝낸다. 정상 실행에서 가장
   중요한 정보는 "문제 없음" 이고, 그게 수십 줄에 묻히면 안 된다.
2. **오래 걸리는 건 돌고 있음을 보여준다.** nvim 플러그인 설치는 몇 분인데
   침묵하면 멈춘 건지 알 수 없다.
3. **실패했을 때만 자세히.** 성공한 명령의 출력은 버린다. 실패하면 그 출력과
   *다음에 무엇을 해야 하는지* 를 같이 보여준다. "위 출력 확인" 은 안내가 아니다.

rich 를 쓴다. 파이프로 넘길 때는 rich 가 알아서 색과 스피너를 끈다.
"""

from __future__ import annotations

from rich.console import Console
from rich.padding import Padding
from rich.text import Text

LABEL_WIDTH = 20


class Step:
    """한 단계. 컨텍스트 매니저로 쓰면 도는 동안 스피너가 보인다."""

    def __init__(self, ui: "UI", label: str) -> None:
        self.ui = ui
        self.label = label
        self._status = None
        self._done = False

    def __enter__(self) -> "Step":
        self._status = self.ui.console.status(
            Text(self.label, style="bold"), spinner="dots")
        self._status.start()
        return self

    def __exit__(self, exc_type, exc, tb) -> bool:
        self._stop()
        if exc_type is not None and not self._done:
            self.fail("예상치 못한 오류", output=str(exc))
        return False

    def _stop(self) -> None:
        if self._status is not None:
            self._status.stop()
            self._status = None

    def progress(self, text: str) -> None:
        """스피너 옆 글자를 바꾼다. 진행 중인 내용을 알린다."""
        if self._status is not None:
            self._status.update(Text(self.label + "  " + text, style="bold"))

    def _line(self, mark: str, style: str, summary: str) -> None:
        self._stop()
        self._done = True
        pad = self.label + " " * max(1, LABEL_WIDTH - _width(self.label))
        self.ui.console.print(
            "  [{}]{}[/{}] {}[dim]{}[/dim]".format(style, mark, style, pad, summary),
            highlight=False)

    def ok(self, summary: str = "") -> None:
        self._line("✓", "green", summary)

    def skip(self, summary: str = "") -> None:
        self._line("·", "dim", summary)

    def warn(self, summary: str, hint: str = "") -> None:
        self._line("⚠", "yellow", summary)
        self.ui.warnings += 1
        if hint:
            self.ui.hint(hint)

    def fail(self, summary: str, output: str = "", hint: str = "") -> None:
        self._line("✗", "red", summary)
        self.ui.failures += 1
        if output:
            self.ui.detail(output)
        if hint:
            self.ui.hint(hint)


def _width(s: str) -> int:
    """한글은 두 칸을 차지한다. 라벨 정렬이 어긋나지 않게."""
    return sum(2 if ord(c) > 0x1100 else 1 for c in s)


class UI:
    def __init__(self, verbose: bool = False) -> None:
        self.console = Console()
        self.verbose = verbose
        self.warnings = 0
        self.failures = 0

    def title(self, text: str, subtitle: str = "") -> None:
        self.console.print()
        self.console.print("[bold]{}[/bold]".format(text), end="")
        if subtitle:
            self.console.print("  [dim]{}[/dim]".format(subtitle), end="")
        self.console.print("\n")

    def step(self, label: str) -> Step:
        return Step(self, label)

    def detail(self, text: str, limit: int = 12) -> None:
        """실패한 명령의 출력. 길면 뒤쪽만 — 원인은 대개 마지막에 있다."""
        lines = [l for l in text.rstrip().splitlines() if l.strip()]
        if not lines:
            return
        self.console.print()
        clipped = len(lines) > limit and not self.verbose
        for line in (lines[-limit:] if clipped else lines):
            # Padding 을 쓰는 이유: 긴 줄이 접힐 때 이어지는 줄도 같이
            # 들여써진다. 그냥 문자열 앞에 공백을 붙이면 첫 줄만 들여써지고
            # 접힌 뒷줄이 왼쪽 끝으로 튀어나온다.
            self.console.print(Padding(Text(line, style="dim"), (0, 0, 0, 6)))
        if clipped:
            self.console.print(
                "      [dim]…앞의 {}줄 생략 (--verbose 로 전부)[/dim]".format(
                    len(lines) - limit))
        self.console.print()

    def hint(self, text: str) -> None:
        """다음에 무엇을 할지. 줄바꿈으로 여러 개를 줄 수 있다."""
        for i, line in enumerate(text.splitlines()):
            prefix = "      → " if i == 0 else "        "
            self.console.print("{}[cyan]{}[/cyan]".format(prefix, _escape(line)),
                               highlight=False)
        self.console.print()

    def note(self, text: str) -> None:
        self.console.print("      [dim]{}[/dim]".format(_escape(text)),
                           highlight=False)

    def done(self, ok_message: str) -> int:
        """마무리. 종료코드를 돌려준다."""
        self.console.print()
        if self.failures:
            self.console.print("[red]실패 {}건[/red] — 위 → 를 따라 해결하고 "
                               "다시 실행할 것".format(self.failures))
            return 1
        if self.warnings:
            self.console.print("[yellow]확인할 것 {}건[/yellow]".format(self.warnings))
            return 1
        self.console.print("[green]{}[/green]".format(ok_message))
        return 0


def _escape(s: str) -> str:
    return s.replace("[", "\\[")
