# provision — agent prompt for machine setup

Prereqs (the true human-only core, ~5 min): a GitHub account exists and the
browser is logged into it; Cursor (or any agent runner) is installed and
signed in. Paste everything below into an agent. You'll be needed three
times, ~2 minutes total: a sudo/GUI ok for Xcode CLT, running `gh auth login`
in your own terminal when prompted, and the Bugbot install click.

---

```text
You are provisioning a fresh macOS machine for development. Work autonomously,
with exactly two human checkpoints, marked below.

CONSTRAINTS:
- No Homebrew, no nvm, no global npm packages
- Write only to ~/.local, ~/.zshrc, and ~/.gitconfig
- Ask before running anything with sudo; never store credentials in files
- Detect the CPU arch (`uname -m`: arm64 vs x86_64) and download accordingly

CAPABILITY CHECK (do this first, silently): determine whether you have a
browser-control tool available (chrome-devtools MCP, Playwright MCP, a
built-in browser tool, or similar) attached to a browser logged into the
intended GitHub account. A browser tool that exists but is signed out of
GitHub counts as BROWSER=no. Set BROWSER=yes/no and use it at step 8.
Do not install a browser tool to get it — absence is the normal case.

EXECUTION NOTES:
- If your harness sandboxes shell commands (restricted network/filesystem),
  run downloads and `gh auth` with full network access from the start; if a
  network command fails with Forbidden/EPERM/timeout, retry it unsandboxed
  ONCE before debugging the command itself.
- Newly installed binaries are not on PATH yet. Invoke them by absolute path
  (~/.local/node/bin/npm, ~/.local/bin/gh) until step 4 lands, and export
  PATH in your own shell session immediately after each install.

TASKS, in order:

1. Xcode command line tools (needed for git):
   - If `xcode-select -p` succeeds, skip.
   - Else attempt headless install: create the sentinel file
     /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress, then
     `softwareupdate -l` to find the "Command Line Tools" label, then
     `softwareupdate -i "<label>"` — CHECKPOINT: ask me before sudo if needed.
   - If that fails, run `xcode-select --install` and tell me to click the
     dialog; poll `xcode-select -p` until it succeeds.

2. Node LTS (v22), no sudo:
   - Download the official tarball for this arch from
     https://nodejs.org/dist/latest-v22.x/ (darwin-arm64 or darwin-x64),
     extract to ~/.local/node, symlink node/npm/npx into ~/.local/bin.

3. GitHub CLI, no sudo:
   - Download the latest macOS release from
     https://github.com/cli/cli/releases/latest — NOTE: macOS assets ship as
     .zip (gh_<ver>_macOS_arm64.zip or _amd64.zip), not .tar.gz. Discover the
     exact asset name from the release JSON
     (https://api.github.com/repos/cli/cli/releases/latest) rather than
     guessing it. Unzip, put bin/gh in ~/.local/bin.

4. PATH: ensure ~/.zshrc has `export PATH="$HOME/.local/bin:$PATH"` (append
   once, idempotently). Use the full path for this session.

5. GitHub auth — HUMAN-RUN, do not attempt `gh auth login` yourself. The
   login command is a long-polling interactive process that dies in agent
   harnesses (timeouts, sandboxes, no TTY), stranding the device code.
   - First check `~/.local/bin/gh auth status` — the machine may already be
     authed; if so, report the username and skip ahead.
   - Otherwise CHECKPOINT — print this for me and wait:
     "In YOUR OWN terminal (Terminal.app, not me), run:
        ~/.local/bin/gh auth login --hostname github.com --git-protocol https --web
      Follow its prompts: it shows a code, opens/points you to
      https://github.com/login/device, and finishes when you authorize in a
      browser logged into the INTENDED account. Reply 'done' here after it
      reports success."
   - After I confirm, verify with `gh auth status` and report the username.
     If it's not the account I expect, I'll say so — instruct me to run
     `gh auth logout` and repeat.

6. Git identity, derived from the session (never ask me to type an email):
   - user.name = the gh username
   - user.email = <id>+<username>@users.noreply.github.com via `gh api user --jq .id`

7. Verify: locate doctor.sh in the dotfiles checkout this prompt came from
   (common locations: ~/code/dotfiles/bootstrap/doctor.sh,
   ~/.dotfiles/bootstrap/doctor.sh — ask me for the path if you can't find
   it). Run it and iterate until exit 0. If it doesn't exist on this
   machine, re-check each item above and summarize.

8. Bugbot / Cursor GitHub App (no API exists for user-level app installs):
   - If BROWSER=yes: navigate https://cursor.com/dashboard → Bugbot / GitHub
     integration → start the Cursor GitHub App install for the account gh
     is authed as, select all repositories, and proceed to the final
     grant screen — then STOP and tell me to review the permissions and
     click Install myself. Hand control to me on any re-auth prompt.
   - If BROWSER=no: print this instruction block for me:
     "Open https://cursor.com/dashboard → Bugbot / GitHub integration →
      Install the Cursor GitHub App, choosing the account gh is authed as.
      Grant all repositories (or add each repo later). Docs:
      https://cursor.com/docs/bugbot"
   - Either way, note in the final report that the install is only truly
     verified by a smoke PR on the first real repo.

FINAL REPORT: versions installed (node, gh, git), gh username, git identity,
doctor.sh result, and any step skipped or improvised.
```

---

## How the browser handling works

The prompt assumes NO browser tool — that's the normal case, and step 8
degrades to printing precise human instructions. If a browser MCP
(chrome-devtools-mcp, Playwright MCP, Cursor's browser control, Claude in
Chrome) happens to be attached to a profile logged into the intended account,
the agent detects it up front and drives the Bugbot navigation itself, with
two deliberate limits baked into the prompt:

1. **The final grant click is always yours.** The agent stops at the
   authorize/install screen so you read the scopes before approving —
   OAuth grants are the category of action to review, not delegate.
2. **Re-auth hands control back.** GitHub often triggers sudo-mode
   (password/2FA) exactly on those screens; the agent is told to yield
   rather than attempt credentials, which it should never have.

## What remains genuinely human, and why

- **GitHub account creation + 2FA** — CAPTCHA, email verification, and 2FA
  enrollment; also not something to delegate to an agent regardless of tooling.
- **Installing + signing into Cursor** — the bootstrap paradox: something has
  to run the first agent.
- **Running `gh auth login` in your own terminal** — learned the hard way:
  it's a long-polling interactive command built for a human TTY. Agent
  harnesses kill it (timeouts, sandboxes, no real TTY), stranding the device
  code. The agent verifies the result; the human runs the command. ~60s.
- **A sudo/GUI ok for Xcode CLT** and the Bugbot app-install click (agent
  can navigate up to the grant screen with a browser tool; the click is yours).
- Either way, the smoke PR in new-project.md is the ground-truth check that
  the app install actually worked.
