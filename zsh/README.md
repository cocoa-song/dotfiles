# zsh

Three files, split by *when zsh reads them*. Getting this wrong is the most
common way for configuration to look present but be invisible.

| File | Read by | Holds |
|---|---|---|
| `zshenv` **(not tracked)** | **every** zsh — scripts, `zsh -c`, non-interactive | PATH, environment variables |
| `zprofile` | login shells, once | `brew shellenv`, PATH precedence |
| `zshrc` | interactive shells | plugins, completion, history, aliases, keybindings |

`bin/setup` writes `~/.zshenv`; the other two are symlinks into this directory.

## Why `~/.zshenv` is not in this repository

It carries machine-bound values — the App Store Connect key ID and private-key
path — and this repo is public. `bin/setup` asks for what it needs and writes the
file. The shape:

```zsh
# ~/.zshenv — read by every zsh. No output, no slow work.
typeset -U path PATH
path=($HOME/.local/bin $path)
export ARCHIVE_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"
export ASC_KEY_ID=... ASC_KEY_PATH=...
[[ -n $ASC_ISSUER_ID ]] || export ASC_ISSUER_ID="$(security find-generic-password -s ASC_ISSUER_ID -w 2>/dev/null)"
```

**It has to be `.zshenv`, not `.zshrc`.** `.zshrc` is read *only by interactive
shells*, so a non-interactive call such as `zsh -c "ship ..."`, a script, or a
launchd job would see none of these values. That failure is silent: the variable
is simply empty.

The `ASC_ISSUER_ID` line guards on the variable already being set so nested shells
skip the Keychain lookup — the parent exports it, children inherit it.

> The Keychain read only works in a GUI (Aqua) session. Over SSH, in a launchd
> job, or inside an agent shell, `security` cannot unlock the login keychain and
> returns empty with rc=36. That is not a broken Keychain item.

## PATH is set in two places on purpose

`.zshenv` puts `~/.local/bin` first so non-interactive shells can find `ship`,
`uia`, and friends. Then `.zprofile` runs `brew shellenv`, which prepends
Homebrew — so `.zprofile` re-asserts `~/.local/bin` afterwards.

`typeset -U path PATH` makes that a move rather than an append, so the entry never
appears twice. Without it, PATH grew a duplicate on every nested shell.

This ordering matters: `ship`, `uia`, and `tiny-press` exist both in
`~/.local/bin` and as brew formulae. The wrong precedence runs the wrong binary.

## Everything external is guarded

antidote, starship, fzf, and eza are each called only when present. On a machine
where `brew bundle` has not run yet, the shell still starts cleanly — you lose
plugins, the prompt, and the `ls` aliases, but nothing errors.

The antidote path follows `HOMEBREW_PREFIX` (exported by `brew shellenv` in
`.zprofile`, which runs first), so it resolves on Intel Macs at `/usr/local` too.
Hardcoding `/opt/homebrew` made this fail *silently* there — the guard swallowed
it and plugins just never loaded.

fzf is guarded on `[[ -t 0 ]]`, not on the `zle` option. A tty-less interactive
shell (`zsh -i -c ...`) still has `zle` on, so that guard never fired and fzf
printed `can't change option: zle` twice on every such invocation.

## Plugins

`zsh_plugins.txt` is tracked; the plugins themselves are not. antidote clones them
into `~/.zsh/plugins` on first shell start and regenerates the static bundle
whenever the list is newer.

**`ANTIDOTE_HOME` is deliberately moved off its default of `~/Library/Caches`.**
An OS cache purge deletes the plugins but leaves the generated
`~/.zsh_plugins.zsh` behind — every shell then sources missing paths and errors,
and antidote does not repair itself because the `.txt` is not newer than the
bundle. This was reproduced accidentally while moving the directory.

Three plugins, chosen by measurement:

- `zsh-autosuggestions` — no built-in equivalent
- `zsh-completions` — adds to `fpath` only, effectively free
- `zsh-syntax-highlighting` — kept over `fast-syntax-highlighting`, which costs
  2.2× to load (+10.5 ms). "Fast" refers to redraw speed while typing, not startup.

History prefix search uses the built-in `up-line-or-beginning-search` widget
rather than a plugin; substring search anywhere in the line is fzf's `Ctrl-R`.

## compinit is cached for 24 hours

A full `compinit` security scan costs ~27 ms, the single largest startup item. The
dump is rebuilt only when it is more than a day old; otherwise `compinit -C` skips
the check, saving ~18 ms.

The cost: **a newly installed completion may not appear for up to a day.** To pick
it up immediately:

```zsh
rm ~/.zcompdump && exec zsh
```

## Terminal integration

Ghostty injects its shell integration only into shells it spawns *directly* —
not into zellij or tmux panes, not into `exec zsh`. Since zellij is in daily use,
`zshrc` sources the integration explicitly when `GHOSTTY_RESOURCES_DIR` is set.
Re-sourcing in a directly-spawned shell is harmless; the script guards itself with
`_ghostty_state`.

Without this, panes lose prompt marking and new splits do not inherit the working
directory.
