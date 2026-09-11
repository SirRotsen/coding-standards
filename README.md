# coding-standards

The single source of truth for R.J. Nestor's coding standards across every repository he owns. `CODING-STANDARDS.md` is the general law; `REVIEW.md` is the pull-request review rubric; `session-start.sh` is the hook that delivers both.

Repos consume the documents live and the script by vendoring. Each repo keeps its own reviewed copy of `session-start.sh` at `.claude/hooks/session-start.sh`; that script fetches the two documents from `https://raw.githubusercontent.com/SirRotsen/coding-standards/main/` and prints them into the session. The documents—the part that changes—are never copied into a repo; the script—the part that executes—is never fetched and run unreviewed. A change to the script here rolls out by PR to each repo, which is the point: what runs at session start only changes through that repo's own review gate.

Repo-specific rules stay in that repo's `CLAUDE.md`. This repo wins on generalities; the repo's `CLAUDE.md` wins on specifics.

To change a standard: edit the file here and push. The next session in every repo has the new text.
