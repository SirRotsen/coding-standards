# Review rubric

## The fresh-context rule

The reviewer sees three things: the diff, the repository, and the intent the PR description claims. It never sees the transcript, the session, or the reasoning that produced the code. A review run inside the authoring session is not a review—it's the same mind agreeing with itself, and it will confirm whatever the author already believed. If you are reading this in the session that wrote the code, stop and hand the PR to a fresh one.

Fresh context is the requirement; the mechanism is not. Either of these qualifies:

- **A new cloud session**, opened against the repository and given the PR number.
- **A subagent spawned by the authoring session.** A subagent has its own context window and does not inherit the transcript, so it meets the rule as written. A forked subagent is the exception: a fork inherits the authoring transcript wholesale, so it is the authoring context under another name and does not qualify.

What disqualifies a review is the authoring context reaching the reviewer, not which of the two supplied it.

## What skips review

A PR skips review only when every changed line is one of these:

- **Code comments.**
- **Prose in documentation files** that humans read and nothing executes, parses, or loads.
- **Wording inside an existing user-facing string**—a label, a message, page copy—with nothing around the string changed.

Never exempt, whatever the diff looks like: any file an agent loads as instructions (`CLAUDE.md`, `CODING-STANDARDS.md`, `REVIEW.md`, skills, hook scripts), CI workflows, configuration, and anything touching sign-in, money, stored data, or deploys. When unsure, it is not exempt—the author judging its own change trivial is the judgment this rubric exists to check.

An exempt PR opens the way the repo's CI calls for—draft, or ready where drafts still run CI—and still passes CI. Its Provenance section names the exemption: "Review skipped: comments only."

## Choosing the reviewer

The author picks the model: **Sonnet by default; Opus only for substantial or judgment-heavy changes.** The pick is made before invoking, and it is the author's own assessment of how hard the change is to get right—not how long it took to write. A change that is short but touches auth, money, data loss, or anything ruled is judgment-heavy.

That assessment never reaches the reviewer. It selects who reviews; it is not part of the prompt.

## Invoking a review

A reviewer fetching this rubric by URL fetches the raw text (`curl` on the raw.githubusercontent.com address), never through a summarizing fetch tool—summarizers have paraphrased and garbled this document, and a review against a paraphrase is a review of a different rubric.

A review is handed nothing but the repository and a number: **"Review PR #N per REVIEW.md"**. Nothing else—no summary, no context, no explanation of what the author was trying to do—because everything the reviewer is allowed to know is already in the repo and the PR description.

When the authoring session spawns the reviewer, that prompt is the whole prompt, verbatim. The author writes no framing of any kind—not the shape of the change, not how long it should take, and above all not that it is small. Handing the reviewer the author's own belief about the change defeats the point of asking someone else, and "this one's trivial" is the belief most likely to be the thing that's wrong.

## The verdict lands on the PR

The review is posted as a comment on the draft PR, with `gh`, **before the PR is marked ready**. Where the repo's CI has not yet been taught to skip drafts and the PR is therefore opened ready, the review posts as the PR's first comment instead. The audit trail lives on the PR, not in a session nobody will reopen. Whoever merges records the reviewing model in the PR's Provenance section.

The reviewer posts its own comment where it can reach GitHub. Where it can't, the author posts the review verbatim, including the findings it disagrees with; disagreement goes in a reply underneath, never into the text. An author's summary of a review of their own work is not the review, and the record has to survive the author disagreeing with it.

## After a fix: when to re-review

**A PR gets at most two review passes: one full review, then one fix check.** R.J.'s ruling, 2026-09-22: "half the time its reviews are well past the point of diminishing returns but it keeps going anyway."

The author answers the full review in one sweep—every finding fixed, or disagreed with in a reply on the PR—before anything else happens. Then:

- **Typo, comment, rename, formatting, or the PR description**—no fix check; mark the PR ready.
- **Anything touching logic or control flow**—one fix check by a **new** fresh reviewer, at the model the fixes' own complexity calls for, with the PR still in draft. It is handed **"Check the fixes to the review on PR #N per REVIEW.md"** and checks only the review's findings and the code the fixes touched, not the whole PR again.

After the fix check, the only findings still fixed before merge are the ones that would lose data, let one tenant reach another's, open a sign-in or permission gap, or crash a page. Everything else goes on the repo's worklist, or to R.J. as a question. No third pass runs unless R.J. asks for one.

A fix CI forced after the PR was marked ready goes back to draft first. It gets a fix check only if it touches logic, and that check counts as the second pass if one has not already run.

The reviewer who wrote the finding is not the one who checks the fix: it has now seen the author's reasoning about that code and is no longer fresh on it.

## The checks

**Does it do what the Intent section claims?** Read the intent first, then the diff. If the diff does something the intent doesn't describe, that's a finding even when the extra thing is good.

**Does it stay inside the declared blast radius?** Anything changed outside what the PR said it would touch gets named, whether or not it looks harmless.

**Security**, where the change reaches any of these:
- **Queries**: parameterized only. String-built queries are a finding, no exceptions and no "the input is safe here."
- **Output**: anything reaching a page, a template, or a response is escaped for where it lands. User input, stored values, URL parameters.
- **Auth**: anything that is supposed to be gated actually checks, and checks *before* it does the work rather than after.
- **Uploads and other untrusted input**: type and size validated, stored where it cannot be executed, never named from user input.

**Does it touch secrets, database schema, or shared directories—and does the PR say so?** Credentials never live in the repository. A schema change or a shared-directory change that isn't declared in the PR is a finding on its own, because the PR description is what R.J. reads.

**Comment discipline**, per the comment law. Bloated comments are a rubric violation, not a style preference: they pad the diff and make it unreadable, and the diff is R.J.'s only window into work he didn't write.

**Does every new test trace to the spec or an invariant?** A test pinning something the spec doesn't say is a finding.

**Does it write anything twice, or narrate?** A ruling copied from the spec into a worklist, a comment or a second doc, and any spec or doc edit that records how the build went rather than what the feature does, is a finding.

**Does the PR assert anything a reader of this repository cannot check?** Claims about what a server does, what a deploy ships, what a service returns, what another repo contains—none of that is verifiable from here, and agreeing with it is not review. A repo's `CLAUDE.md` is not evidence on any of it: it is repo memory, and it has been wrong.

**Would anything here surprise the person who reads only the PR description?** If yes, say what and why. This is the catch-all, and in practice it's the check that earns its keep.

## Findings

Say what's wrong, where, and what it would cost. Distinguish "this will break" from "I'd have done it differently"—the second is worth saying once and never worth blocking on.

Findings about the PR description itself—a stale file count, a blast-radius list that trails the diff, wording overtaken by a fix—are fixed before merge and never, on their own, call for a fix check.

---

This file gets edited the day a review misses something—or the day one is skipped and the skip costs something. It is the review culture, versioned.
