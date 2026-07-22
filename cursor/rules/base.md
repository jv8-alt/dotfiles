# Commands
<!-- fill in the project's actual commands -->
- `npm run dev`: start the dev server
- `npm run typecheck`: must pass before any commit
- `npm test`: prefer single test files for speed while iterating

# Code style
- Strict types, ES modules
- No new dependencies without asking
- Match existing patterns; when in doubt, find the canonical example file and cite it

# Project invariants
<!-- REPLACE: the load-bearing rules unique to this project, e.g.
     "all database access goes through the repository layer in src/db/" -->

# Workflow
- Typecheck after each series of edits
- Small commits, one concern each
- One branch = one concern = one PR; never bundle unrelated changes
- Any plan that changes structure (components, boundaries, protocols, integrations) includes a target-architecture diagram and flow diagram(s) for key runtime paths (Mermaid), presented before implementation — not just a task list
