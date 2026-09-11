# coding-standards

The single source of truth for R.J. Nestor's coding standards across every repository he owns. `CODING-STANDARDS.md` is the general law; `REVIEW.md` is the pull-request review rubric; `session-start.sh` is the hook that delivers both.

Repos consume it at session start rather than vendoring it: a SessionStart hook fetches the two documents from `https://raw.githubusercontent.com/SirRotsen/coding-standards/main/` and prints them into the session. A repo either runs `session-start.sh` directly or keeps a thin wrapper that does. Nothing here is copied into a repo—a copy goes stale silently, and the point of this repo is that there is one text.

Repo-specific rules stay in that repo's `CLAUDE.md`. This repo wins on generalities; the repo's `CLAUDE.md` wins on specifics.

To change a standard: edit the file here and push. The next session in every repo has the new text.
