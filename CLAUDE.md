# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->


## Build & Test

_Add your build and test commands here_

## Architecture Overview

_Add a brief overview of your project architecture_
- This project uses the feature based architecture, the lib folder will contain a shared folder with any shared logic/widgets/repositories/... and for each feature, it must have a domain/data/presentation folder
- Riverpod 3.x.x with code generation will be used as a state management solution for this project. Create class based providers if the state is mutable and function based providers if the state cannot be mutable. 
- There must be separation of concerns, the code must follow the following structure UI -> Provider -> Service -> Repository -> DataSource
- The UI must follow the atomic design principles. Each page must be composed of smaller organisms / molecules and atoms. Only the page can extend ConsumerWidget/ConsumerStatefulWidget if needed, State and Callbacks must be passed as parameters from the page down to its smaller organisms ... Organisms / Molecules / Atoms must be private widgets in the same file as the page. If a widget needs to be shared it must have a DocCentral prefix (example: DocCentralButton)
- You must **never** use harcoded strings, always create English French and arabic strings and call AppLocalizations to use the localized strings.
- For each developed feature, develop unit and integration tests, and ensure that tests do not have any issues at the end of a ticket. and for each new ticket developed, tests must always pass. 
## Conventions & Patterns

_Add your project-specific conventions here_
