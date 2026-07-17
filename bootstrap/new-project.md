# new-project — agent bootstrap prompt

Fill in the header, then paste the ENTIRE block below (header included) into an
agent. Prereq: `doctor.sh` exits 0 and, if you want PR review, the Cursor
GitHub App (Bugbot) is installed under the intended GitHub account.

---

```text
PROJECT: <name>                      # repo + directory name, kebab-case
VISIBILITY: private                  # private | public — see "Private repo
                                     # notes" below for what private changes
STACK: node-ts                       # node-ts | describe another stack; the
                                     # node-ts recipe is spelled out below,
                                     # adapt its spirit for anything else
EXTRA_DEPS:                          # project-specific packages beyond the
                                     # stack recipe, e.g. "zod" or "pg" plus
                                     # any @types/* devDeps; blank = none
RULESET: no                          # no = solo/sprint repo, skip step 6;
                                     # yes = long-lived or multi-contributor
DIR: ~/dev                           # parent directory for the project
INVARIANTS:                          # project-specific rules for .cursor/rules,
  - <e.g. "all database access goes through the repository layer in src/db/">
DOTFILES: ~/.dotfiles                # where cursor/ and templates/ live; if
                                     # absent, generate equivalents inline

You are bootstrapping a new project on this machine. Work autonomously; only
stop if a REQUIRED precondition fails.

PRECONDITIONS — verify all before doing anything else:
1. `git --version` works
2. `node -v` is v20+ (only if STACK is node-ts)
3. `gh auth status` shows a logged-in user — record the username and use it
   everywhere; NEVER prompt for credentials or create SSH keys
4. `git config --global user.name` and `user.email` are set. If email is
   missing, derive the noreply address: `gh api user --jq .id` then
   <id>+<username>@users.noreply.github.com
If 1–3 fail, STOP and report exactly which one; do not install anything to fix it.

CONSTRAINTS:
- Do NOT install Homebrew, nvm, Docker, or any global npm packages
- Do NOT touch anything outside DIR/PROJECT and ~/.gitconfig (precondition 4 only)
- HTTPS remotes only
- If a DOTFILES template exists, copy it rather than authoring from scratch

TASKS, in order:

1. Create DIR/PROJECT, `git init`.

2. Scaffold per STACK. For node-ts:
   - deps: fastify + anything in EXTRA_DEPS; devDeps: typescript, tsx,
     vitest, @types/node + any EXTRA_DEPS type packages
   - tsconfig: nodenext modules, es2022 target, strict, rootDir src, outDir dist
   - scripts: dev = "tsx watch src/server.ts", typecheck = "tsc --noEmit",
     test = "vitest run"
   - .gitignore: node_modules/, dist/, logs/, scratch/, .env
   - src/server.ts: minimal fastify server, GET /health → {ok:true}
   - one trivial passing vitest test
   For any other STACK: equivalent minimal scaffold — a runnable entrypoint,
   a typecheck-or-lint command, a test command, one passing test.

3. Commit, then: `gh repo create PROJECT --VISIBILITY --source=. --push`

4. CI: copy DOTFILES/templates/ci-node.yml to .github/workflows/ci.yml
   (or write the equivalent for the STACK: run typecheck/lint + tests on
   push to main and on every pull_request). Commit and push.

5. Cursor config, committed into the repo:
   - .cursor/rules/main.md: start from DOTFILES/cursor/rules/base.md, fill in
     the project's actual commands, and replace the invariants placeholder
     with the INVARIANTS list from the header
   - .cursor/commands/pr.md: copy from DOTFILES/cursor/commands/pr.md
   Commit and push.

6. ONLY IF RULESET is yes: branch ruleset on main requiring the CI check
   to pass, via `gh api`. Caveat: on FREE-plan accounts, rulesets are not
   enforced on private repos (requires GitHub Pro). Attempt it once; if
   the API rejects it, reports it unenforced, or fights you for more than
   2 minutes, skip WITHOUT retrying and state clearly in the final report:
   "merge gate is convention only — CI shows on PRs but won't block
   merging; enforce manually or upgrade to Pro."
   If RULESET is no, skip this step silently — solo and sprint repos don't
   need a merge gate; the human is the merge gate.

7. VERIFICATION LOOP: branch "smoke-test", add one trivial file, push, open
   a PR with `gh pr create --fill`. Poll `gh pr checks` until CI passes —
   if it fails, fixing it is part of your job. Do NOT merge; leave the PR
   open and return its URL so the human can confirm the review bot
   commented before merging.

FINAL REPORT: repo URL, smoke PR URL, CI status, anything skipped or improvised.
```

---

## Private repo notes (the default)

Three things change versus public — none blocking, one affecting step 6:

- **Actions minutes are metered**: ~2,000 min/month on the Free plan
  (unlimited for public). A 1–2 minute CI job means hundreds of PR cycles —
  fine for most projects. Usage: https://github.com/settings/billing
- **Bugbot**: the free tier targets public/hobby use; private repos run on
  the 14-day trial or the paid add-on. Details: https://cursor.com/docs/bugbot
- **Rulesets aren't enforced on Free-plan private repos** (needs GitHub Pro,
  https://github.com/settings/billing/plans). Only relevant when RULESET is
  yes; the default (no) sidesteps it entirely — for solo and sprint repos,
  you are the merge gate.

## Notes

- The unmerged smoke PR is deliberate: whether Bugbot comments is the one
  thing the agent can't verify or fix (it's a dashboard-side app install).
  The run ends by handing you exactly that artifact.
- The hard-stop preconditions exist to block the classic failure mode:
  an agent "helpfully" installing a package manager or minting SSH keys
  under the wrong identity when auth is missing.
- Nothing in this file is identity- or machine-specific, so it's safe in a
  public dotfiles repo; identity always comes from the live `gh` session.
