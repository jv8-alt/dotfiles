# bootstrap/

Fresh machine → any new project with CI, review bot, and Cursor config, in three passes. Safe for a public repo: nothing here contains identity, secrets, or machine-specific paths — identity is always derived at runtime from `gh auth`.

## The three passes

**1. Human pass (~5 min, once per machine).**
Only the genuinely non-delegable core:

- GitHub account (if a fresh identity): [github.com/signup](https://github.com/signup), then enable 2FA at [github.com/settings/security](https://github.com/settings/security) — CAPTCHA and authenticator enrollment. Stay logged in; the browser session is the identity everything else derives from.
- Install Cursor from [cursor.com/download](https://cursor.com/download) and sign in — the bootstrap paradox: something has to run the first agent.

**2. Provision pass (once per machine): scripts do the work, humans do the waiting.**
Design rule: agents never own anything that retries, polls, or waits — script loops cost milliseconds, agent loops cost narrated LLM round-trips. So `install.sh` (idempotent, no sudo) installs Node + gh into `~/.local` and configures PATH; you run `gh auth login` in your own terminal (interactive by design) and click the CLT dialog and Bugbot grant screen. Run the three-command manual path at the top of `provision.md` yourself, or paste `provision.md` into an agent to get sequencing, one-shot verification, and Bugbot navigation on top — same steps either way.

`doctor.sh` also stands alone — rerun it anytime:

```sh
./doctor.sh        # checks toolchain + auth, reports what's missing
./doctor.sh --fix  # also sets git identity from the gh session (noreply email)
```

Idempotent, read-only unless `--fix`. Exit code 0 = machine ready.

**Optional, anytime: `shell.sh` — pretty prompt.** Same idempotent/no-sudo pattern as `install.sh`, but purely cosmetic so it's not part of the numbered passes. Installs Starship (prompt) + JetBrainsMono Nerd Font + zsh-autosuggestions + zsh-syntax-highlighting, all into `~/.local` / `~/Library/Fonts`, and writes `~/.config/starship.toml` with a GitHub icon segment (shows `org/repo` when the current repo's remote is GitHub). Never overwrites an existing `starship.toml`. One manual step it can't script: set the Nerd Font in Terminal.app ▸ Preferences ▸ Profiles ▸ Font. `doctor.sh` reports its status (optional, non-blocking) in the "optional" section.

**3. Project pass (once per project): paste `new-project.md` into an agent.**
Open `new-project.md`, fill in the header block (name, visibility, stack, invariants), paste the whole thing into an agent. It scaffolds, creates the repo, wires CI from `../templates/`, seeds `.cursor/` from `../cursor/`, and ends with an **unmerged** smoke PR — the artifact you use to verify CI ran and Bugbot commented, since the bot install is the one thing an agent can't check.

## Layout

```
bootstrap/
  README.md          this file
  install.sh         deterministic toolchain install (node, gh, PATH)
  shell.sh           optional: pretty prompt (starship, nerd font, zsh plugins)
  doctor.sh          machine preflight / verification
  provision.md       machine setup: manual 3-command path + agent wrapper
  new-project.md     agent prompt: new repo (scaffold + CI + smoke PR)
cursor/
  rules/base.md      generic project rules (agent fills the invariants slot)
  commands/pr.md     uniform PR exit for any agent
templates/
  ci-node.yml        Node CI workflow (typecheck + test on PRs)
```

## Conventions these files assume

- Private repos by default. Costs versus public: metered Actions minutes (~2,000/mo free — plenty), Bugbot on trial/paid rather than free tier, and rulesets unenforced without GitHub Pro (see "Private repo notes" in new-project.md). Flip VISIBILITY to public to get all three free.
- HTTPS remotes via gh's credential helper; never SSH keys
- One branch = one concern = one PR; CI runs on every PR (merge-gate ruleset is opt-in via the RULESET flag — solo/sprint repos skip it)
- Commit `.cursor/` into each project so every agent (and teammate) shares conventions
