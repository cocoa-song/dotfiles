# dotfiles

Personal configuration shared across machines.

```
bin/setup      First-time setup on a new machine (run once, right after clone)
bin/sync       Bring an already-configured machine up to date
nvim/          Markdown workbench (Neovim 0.12) — see nvim/README.md
ghostty/       Terminal
zsh/           Shell — see "zsh" below
git/           Shared git config + global ignore — see "git" below
starship.toml  Prompt
Brewfile       Every external tool the above depends on
```

`~/.config/nvim`, `~/.config/ghostty`, `~/.config/starship.toml`,
`~/.config/git/ignore`, `~/.zshrc`, `~/.zprofile`, and `~/.zsh_plugins.txt` are
all symlinks into this repository.

**The scripts are the source of truth.** Prose in this file explains *why*; when
prose and script disagree, the script is right. Do not hand-execute a procedure
that `bin/setup` or `bin/sync` already performs.

## New machine

```bash
git clone https://github.com/hoemoon/dotfiles.git ~/dotfiles
~/dotfiles/bin/setup
```

That is the whole procedure. `setup` stops to ask a few things — the admin
password (installing Homebrew), git name and email, whether this machine does
App Store Connect releases, GitHub login, and whether to move an existing
Ghostty config out of the way. Everything else it does on its own. Re-running it
is safe; anything already done is skipped.

Two things `setup` cannot do, reported at the end only when they apply: copying
the ASC private key (`.p8`) from another machine, and registering the Issuer ID
in the Keychain, which only works from a GUI terminal session.

## Updating an existing machine

```bash
~/dotfiles/bin/sync
```

Pulls, creates any missing symlinks, and reconciles the Brewfile. Safe to re-run.
**It never overwrites anything it did not create** — if a real file occupies a
target path, or a symlink points somewhere else, it warns and moves on, because
that is a decision for a human. Exits 1 when something needs attention.

This is exactly the gap `git pull` leaves. Because the symlinks point into the
repository, **edits to existing files take effect from the pull alone.** What a
pull cannot do is (1) create links for files newly added to the repo and
(2) install newly declared Brewfile entries. `sync` does those two things.

## Layout and rationale

### ⚠ macOS: Ghostty reads config from *two* places

Any Mac that has run Ghostty once has this file:

```
~/Library/Application Support/com.mitchellh.ghostty/config
```

It does **not** replace `~/.config/ghostty/config`. Both are loaded, and this one
is read later, so it wins. Symlinking alone therefore looks like it was silently
ignored. (Measured: after linking, `theme` still came from the App Support copy
and `font-family` was the two files concatenated into four lines.) `setup` offers
to move it aside; by hand:

```bash
mv ~/Library/Application\ Support/com.mitchellh.ghostty/config{,.bak-$(date +%Y%m%d)}
```

Always confirm which one won by observing the result, not by reading the file:

```bash
ghostty +show-config | grep -E '^(font-family =|theme)'
# expected: JetBrainsMono Nerd Font Mono / Sarasa Term K / Flexoki Light
```

### zsh

`bin/setup` creates `~/.zshenv` by asking. What follows is background for
editing it later, or writing it by hand.

The shell does not break if `brew bundle` has not run yet — antidote, starship,
and fzf are each called only when present, so you lose plugins and the prompt but
nothing errors. The antidote path follows `HOMEBREW_PREFIX`, so it also resolves
on Intel Macs (`/usr/local`).

Plugins are cloned by antidote into `~/.zsh/plugins` on first shell start: the
list is tracked, the plugins themselves are not. `ANTIDOTE_HOME` is moved off its
default of `~/Library/Caches` because **an OS cache purge deletes the plugins but
leaves the generated bundle `~/.zsh_plugins.zsh` behind** — every shell then
sources missing paths and errors, and antidote will not repair itself because the
`.txt` is not newer than the bundle.

**`~/.zshenv` is deliberately not in this repository.** It holds machine-bound
values such as the App Store Connect key ID and private-key path, and this repo is
public — the same reasoning as "Why not track `~/.config` itself" below.

```zsh
# ~/.zshenv — read by every zsh. No output, no slow work.
typeset -U path PATH
path=($HOME/.local/bin $path)
export ARCHIVE_DIR="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"
export ASC_KEY_ID=... ASC_KEY_PATH=...
[[ -n $ASC_ISSUER_ID ]] || export ASC_ISSUER_ID="$(security find-generic-password -s ASC_ISSUER_ID -w 2>/dev/null)"
```

It has to be `.zshenv` rather than `.zshrc`: `.zshrc` is read **only by
interactive shells**, so a non-interactive call like `zsh -c "ship ..."` would see
none of these values.

### git

`bin/setup` creates `~/.gitconfig` by asking for a name and email. It is **not**
tracked here — it carries identity plus the gh credential helper, and this repo is
public.

```gitconfig
[include]
	path = ~/dotfiles/git/shared

[user]
	name = ...
	email = ...
```

`[include]` goes **first** on purpose: git lets later values win, so repeating a
key below the include overrides the shared setting on that machine only.

`git/shared` carries only identity-independent tool and display settings (the
delta pager, zdiff3 conflict style, colorMoved). The credential block that
`gh auth setup-git` manages is deliberately left out — gh rewrites it into
`~/.gitconfig` anyway, so tracking it would only create a duplicate.

### Notes vault

`markdown_oxide` treats a directory as the notes root only if it contains
`.moxide.toml`; the path is not baked into the nvim config. To use notes on a new
machine, drop a `.moxide.toml` in that folder — see section 5 of
[nvim/README.md](nvim/README.md).

## Why not track `~/.config` itself

`~/.config` holds more than fifteen directories belonging to other tools —
`gh/`, `github-copilot/`, `configstore/` and friends. Even when no credentials
are visible today, **there is no control over which tool drops a token there
tomorrow.** A whitelist `.gitignore` does not help: one `git add -f` leaks it.
Keeping the repository outside `~/.config` removes that risk structurally.

## The theme lives in two places

Terminal and editor share **one Flexoki palette**. Background `#fffcf0` and
foreground `#100f0f` match exactly, so the window boundary disappears. Switching
to dark means changing both.

| | Light | Dark |
|---|---|---|
| `ghostty/config` | `theme = Flexoki Light` | `theme = Flexoki Dark` |
| `nvim/lua/config/plugins.lua` | `flexoki-light` + `background = "light"` | `flexoki-moon` + `"dark"` |

## History

`nvim/` began as a standalone repository at `~/.config/nvim`. It was moved into a
subdirectory with `git mv`, so history before the move is still reachable via
`git log --follow nvim/<file>`.
