# provision — agent prompt for machine setup

Prereqs (human-only, ~5 min): a GitHub account exists and the browser is
logged into it; Cursor (or any agent runner) is installed and signed in.

Design principle, learned the hard way: **agents must never own work that
retries, polls, or waits.** Every retry in an agent loop costs an LLM
round-trip; the same loop in a script costs milliseconds, and interactive
waits belong to the human. So the mechanical work lives in `install.sh`
(deterministic, idempotent), the interactive work is yours, and the agent
only sequences and verifies.

You can skip the agent entirely — the manual path is three commands:

```sh
~/code/dotfiles/bootstrap/install.sh   # re-run after the CLT dialog if prompted
~/.local/bin/gh auth login --hostname github.com --git-protocol https --web
~/code/dotfiles/bootstrap/doctor.sh --fix
```

…plus the Bugbot app install (https://cursor.com/dashboard → GitHub
integration). The agent prompt below adds sequencing, verification, and
Bugbot navigation on top of exactly that path.

---

```text
You are finishing the setup of a fresh macOS machine. The heavy lifting is
done by scripts and by me — your job is to sequence, verify, and stop at the
marked checkpoints. HARD RULE: never retry or poll anything. Run each command
at most once; if it fails or needs waiting, hand it to me with exact
instructions and wait for my reply.

CAPABILITY CHECK (silent): note whether you have a browser-control tool
attached to a browser logged into the intended GitHub account (signed-out
counts as no). Used only at step 4.

SETUP: locate the dotfiles checkout (common: ~/code/dotfiles,
~/.dotfiles — ask me if not found). Call it $DOTFILES.

1. Run $DOTFILES/bootstrap/install.sh ONCE.
   - Exit 0: report the ✓ lines and continue.
   - Exit 1: it printed a human instruction (usually the Xcode CLT dialog).
     Relay it verbatim, wait for my "done", run the script ONCE more, then
     continue. If it fails a second time, stop and show me the output.

2. CHECKPOINT — GitHub auth (mine, not yours; the login command is
   interactive and long-polling, it will die in your harness):
   - First run `~/.local/bin/gh auth status`. Already authed → report the
     username, skip to 3.
   - Otherwise print:
     "In YOUR OWN terminal, run:
        ~/.local/bin/gh auth login --hostname github.com --git-protocol https --web
      Complete it in a browser logged into the INTENDED account, then reply
      'done'."
   - After my reply, run `gh auth status` ONCE and report the username. Not
     the expected account → tell me to `gh auth logout` and redo; do not
     loop on my behalf.

3. Run $DOTFILES/bootstrap/doctor.sh --fix ONCE. Exit 0 → report the
   summary. Nonzero → show me the ✗ lines and their fix hints verbatim;
   do NOT attempt the fixes yourself unless I say so.

4. Bugbot / Cursor GitHub App (no API for user-level app installs):
   - Browser tool available: navigate https://cursor.com/dashboard →
     Bugbot / GitHub integration → proceed to the app-install grant screen,
     then STOP — I review the permissions and click Install. Yield to me on
     any password/2FA prompt.
   - No browser tool: print:
     "Open https://cursor.com/dashboard → Bugbot / GitHub integration →
      Install the Cursor GitHub App for the account gh is authed as.
      Docs: https://cursor.com/docs/bugbot"

FINAL REPORT: node/gh/git versions, gh username, git identity, doctor.sh
result, and anything skipped. Note that the Bugbot install is only truly
verified by a smoke PR on the first real repo (new-project.md does this).
```

---

## Division of labor, and why

- **install.sh (script)** — downloads, extraction, PATH, arch detection.
  Deterministic and idempotent; a failed download retried by a script costs
  milliseconds, retried by an agent costs a narrated round-trip. Re-running
  it is always safe.
- **Human** — everything interactive or CAPTCHA'd: account creation + 2FA,
  the CLT dialog click, `gh auth login` (long-polling, needs a real TTY),
  the Bugbot grant click. Each is under a minute.
- **Agent** — sequencing, relaying instructions at the right moment,
  one-shot verification (`gh auth status`, doctor.sh), and browser
  navigation up to — never through — grant screens.
- **Ground truth** — the smoke PR in new-project.md proves the whole chain
  (CI + Bugbot) actually works.
