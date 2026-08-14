# dotfiles

Personal configuration shared across machines (macOS).

```
bin/setup      First-time setup on a new machine — run once, right after clone
bin/sync       Bring an already-configured machine up to date
nvim/          Markdown workbench (Neovim 0.12)
ghostty/       Terminal
zsh/           Shell
git/           Shared git config + global ignore
starship.toml  Prompt
Brewfile       Every external tool the above depends on
```

`~/.config/nvim`, `~/.config/ghostty`, `~/.config/starship.toml`,
`~/.config/git/ignore`, `~/.zshrc`, `~/.zprofile`, and `~/.zsh_plugins.txt` are
all symlinks into this repository.

**The scripts are the source of truth.** These documents explain *why*; when a
document and a script disagree, the script is right. Do not hand-execute a
procedure that `bin/setup` or `bin/sync` already performs.

## New machine

```bash
git clone https://github.com/hoemoon/dotfiles.git ~/dotfiles
~/dotfiles/bin/setup
```

That is the whole procedure. **`setup` asks everything up front, then runs to
completion without stopping.** The questions are numbered so you know how many are
left, and anything already configured is not asked about at all — a second run on
a finished machine asks nothing.

What it may ask: git name and email, whether this machine does App Store Connect
releases, whether to install `macism` (which requires trusting a third-party brew
tap), whether to move an existing Ghostty config aside, and whether to log in to
GitHub.

Two things sit outside that block by necessity. Installing Homebrew needs an admin
password, so it happens *before* the questions; `gh auth login` needs a browser, so
it happens *last*. `brew bundle` may also prompt for a password when installing
casks.

Every answer can be supplied as a flag instead, in which case nothing is asked —
useful for automation, and it is how the script is tested:

```bash
~/dotfiles/bin/setup --name "..." --email "..." --no-asc --macism --no-gh
```

See `bin/setup --help`. Both scripts are Python (stdlib only) and run on the
Python 3.9 that ships with the Command Line Tools, since that is the only one
present on a fresh machine.

Two things `setup` cannot do, reported at the end only when they apply: copying
the ASC private key (`.p8`) from another machine, and registering the Issuer ID in
the Keychain, which only works from a GUI terminal session.

## Updating an existing machine

```bash
~/dotfiles/bin/sync
```

Pulls, creates any missing symlinks, and reconciles the Brewfile. Safe to re-run.
**It never overwrites anything it did not create** — if a real file occupies a
target path, or a symlink points elsewhere, it warns and moves on, because that is
a decision for a human. Exits 1 when something needs attention.

This is exactly the gap `git pull` leaves. Because the symlinks point into the
repository, **edits to existing files take effect from the pull alone.** What a
pull cannot do is (1) create links for files newly added to the repo and
(2) install newly declared Brewfile entries. `sync` does those two things.

## Where to look

| If you are… | Read |
|---|---|
| debugging Ghostty theme, font, or a config that seems ignored | [ghostty/README.md](ghostty/README.md) |
| touching the shell — plugins, PATH, env vars, startup time, completion | [zsh/README.md](zsh/README.md) |
| dealing with git identity, the diff pager, or credential helpers | [git/README.md](git/README.md) |
| editing in nvim — LSP, formatters, notes, keymaps | [nvim/README.md](nvim/README.md) |
| switching the color theme (it lives in three files) | [ghostty/README.md](ghostty/README.md) |
| wondering why a value is empty in a script but fine in the terminal | [zsh/README.md](zsh/README.md) |

## Why not track `~/.config` itself

`~/.config` holds more than fifteen directories belonging to other tools — `gh/`,
`github-copilot/`, `configstore/` and friends. Even when no credentials are
visible today, **there is no control over which tool drops a token there
tomorrow.** A whitelist `.gitignore` does not help: one `git add -f` leaks it.
Keeping the repository outside `~/.config` removes that risk structurally.

The same reasoning keeps `~/.zshenv` and `~/.gitconfig` untracked — they carry
identity and machine-bound values, and this repository is public. `bin/setup`
writes them locally.
