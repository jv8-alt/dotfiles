# bootstrap/

Fresh machine → any new project with CI, review bot, and Cursor config, in three passes. Safe for a public repo: nothing here contains identity, secrets, or machine-specific paths — identity is always derived at runtime from `gh auth`.

## The three passes

**1. Human pass (~5 min, once per machine).**
Only the genuinely non-delegable core:

- GitHub account (if a fresh identity): [github.com/signup](https://github.com/signup), then enable 2FA at [github.com/settings/security](https://github.com/settings/security) — CAPTCHA and authenticator enrollment. Stay logged in; the browser session is the identity everything else derives from.
- Install Cursor from [cursor.com/download](https://cursor.com/download) and sign in — the bootstrap paradox: something has to run the first agent.

**2. Provision pass (once per machine): paste `provision.md` into an agent.**
The agent installs Node and gh from official releases into `~/.local` (no sudo, no Homebrew), attempts a headless Xcode CLT install, derives git identity from the gh session, tees up the Bugbot app-install URL, and verifies with `doctor.sh`. You're needed three times, ~2 minutes total: one sudo/GUI ok, running `gh auth login` in your own terminal when the agent prompts you (deliberately human-run — it's a long-polling interactive command that dies in agent harnesses), and the app-install click (agent can navigate you there with a browser MCP; the grant click stays yours).

`doctor.sh` also stands alone — rerun it anytime:

```sh
./doctor.sh        # checks toolchain + auth, reports what's missing
./doctor.sh --fix  # also sets git identity from the gh session (noreply email)
```

Idempotent, read-only unless `--fix`. Exit code 0 = machine ready.

**3. Project pass (once per project): paste `new-project.md` into an agent.**
Open `new-project.md`, fill in the header block (name, visibility, stack, invariants), paste the whole thing into an agent. It scaffolds, creates the repo, wires CI from `../templates/`, seeds `.cursor/` from `../cursor/`, and ends with an **unmerged** smoke PR — the artifact you use to verify CI ran and Bugbot commented, since the bot install is the one thing an agent can't check.

## Layout

```
bootstrap/
  README.md          this file
  doctor.sh          machine preflight
  provision.md       agent prompt: machine setup (tools + auth)
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
- One branch = one concern = one PR; CI required on main via ruleset
- Commit `.cursor/` into each project so every agent (and teammate) shares conventions
