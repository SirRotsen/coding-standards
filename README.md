# coding-standards

The single source of truth for R.J. Nestor's coding standards across every repository he owns, and for the small amount of machinery those repositories share.

| File | What it is |
|---|---|
| `CODING-STANDARDS.md` | The general law. Repo-specific rules stay in that repo's `CLAUDE.md`; this repo wins on generalities, the repo's file wins on specifics. |
| `REVIEW.md` | The pull-request review rubric. |
| `bin/hq` | The bootstrap each repo vendors at `.claude/bin/hq`. |
| `payload/session-start` | What `hq session-start` runs: prints the two documents above, then the repo's publish state. |
| `payload/drop` | What `hq drop` runs: files a task into HQ. |
| `workflows/no-agent-thread.yml` | The CI check that refuses a PR still carrying `Agent-Messages/`. Copied into each repo's `.github/workflows/`. |
| `tests/test-bootstrap.sh` | What `bin/hq` must keep doing, chiefly what it must refuse. Run it against a branch: `tests/test-bootstrap.sh my-branch`. |

## How a repo consumes this

One vendored file, `.claude/bin/hq`, fetched-at-runtime logic behind it. A repo needs:

- `.claude/bin/hq`, copied from `bin/hq`, executable.
- `.claude/.cache/` in `.gitignore`—where the bootstrap keeps the last payload that arrived intact, so an unreachable network degrades to slightly stale instead of nothing. This one is load-bearing, not hygiene: anything sitting there with a shebang is what runs when the fetch fails, so a committed cache would be executable code review never saw.
- `.claude/settings.json` wiring the two entry points: the `SessionStart` hook runs `$CLAUDE_PROJECT_DIR/.claude/bin/hq session-start`, and `permissions.allow` carries `Bash(.claude/bin/hq drop:*)`. That rule matches the literal command text, so `hq drop` is allowed and every other subcommand still prompts. Know what it authorizes: code fetched from this repo, run without a prompt, in the process that holds `HQ_DROP_TOKEN`. That is why the ref is validated, the payload is verified before it is cached, and merging here is gated.
- `.github/workflows/no-agent-thread.yml`, copied from `workflows/`, with `no-agent-thread` set as a required status check in branch protection.
- The repo's own CI workflow carrying the draft-skipping pair `types: [opened, synchronize, reopened, ready_for_review]` and a job-level `if: github.event.pull_request.draft == false`. Both, or merges block—see the Shipping section of `CODING-STANDARDS.md`.

What the bootstrap checks about a payload is that it is a script—a shebang, not a stub. There is no checksum, signature or pin, deliberately: the gate is this repo's own review and required check, which is why they exist.

Changing a payload here changes every repo's next run. Changing `bin/hq` is the one thing that still costs a PR per repo, which is why it does nothing but fetch, verify, cache and exec.

A repo with its own session-setup needs keeps that in its own hook alongside this one. `payload/session-start` stays repo-agnostic; hymnkeep's cloud container prep is the standing example.

## Changing something here

Through a PR, like any other repo: branch, `tests/test-bootstrap.sh <branch>`, draft PR, fresh review, mark ready, CI, merge. Merging to `main` here is what rolls a change out everywhere, which is why this repo carries its own required check rather than resting on the claim that merging here is careful.

To try a payload change before it ships, point a session at the branch: `HQ_BOOTSTRAP_REF=my-branch .claude/bin/hq session-start`.
