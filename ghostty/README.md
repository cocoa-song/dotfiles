# ghostty

`~/.config/ghostty` is a symlink to this directory.

## ⚠ macOS reads config from *two* places

Any Mac that has run Ghostty once has this file:

```
~/Library/Application Support/com.mitchellh.ghostty/config
```

It does **not** replace `~/.config/ghostty/config`. Both are loaded, and this one
is read later, so it wins. Symlinking alone therefore looks like it was silently
ignored.

Measured: after linking, `theme` still came from the App Support copy, and
`font-family` was the two files concatenated into four lines.

`bin/setup` offers to move it aside. By hand:

```bash
mv ~/Library/Application\ Support/com.mitchellh.ghostty/config{,.bak-$(date +%Y%m%d)}
```

**Always confirm which one won by observing the result, not by reading the file:**

```bash
ghostty +show-config | grep -E '^(font-family =|theme)'
# expected: JetBrainsMono Nerd Font Mono / Sarasa Term K / Flexoki Light
```

## The theme lives in three places

Terminal, editor, and git diffs share **one Flexoki palette**. Background
`#fffcf0` and foreground `#100f0f` match exactly, so the window boundary
disappears. Switching to dark means changing all three.

| | Light | Dark |
|---|---|---|
| `ghostty/config` | `theme = Flexoki Light` | `theme = Flexoki Dark` |
| `nvim/lua/config/plugins.lua` | `flexoki-light` + `background = "light"` | `flexoki-moon` + `"dark"` |
| `git/shared` | `delta.syntax-theme = GitHub` | a dark bat theme (`bat --list-themes`) |

## Shell integration does not reach multiplexer panes

Ghostty injects its zsh integration only into shells it spawns directly. zellij
panes, tmux panes, and `exec zsh` do not get it, which silently costs prompt
marking and working-directory inheritance for new splits.

`zsh/zshrc` sources it explicitly — see `zsh/README.md`.
