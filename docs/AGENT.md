# FitLens change workflow

1. Read the applicable `AGENTS.md` instructions. Start with `rtk git status` and scoped diffs for the paths involved. Use RTK for supported commands and scoped native commands when RTK is unavailable.
2. Search for relevant paths and symbols before reading files. Read [APP_SUMMARY.md](../APP_SUMMARY.md) when you need project context. Consult the [changelog](CHANGELOG.md) when its history is relevant to the change.
3. Preserve the user's work and keep edits within the requested scope. When a command fails, record the command, exit status, and first actionable error. Read more of the log if needed to diagnose it.
4. Run checks suited to the change. For Flutter code, format the changed files, run analysis and relevant tests, and inspect visible changes on an available target. Report automated and device or browser checks separately.
5. Update the summary when current behavior changes. After verification, add one dated changelog entry per meaningful implementation or fix batch. Say what changed for the user, why, what was verified, and any open limitation. Leave edits uncommitted unless asked to commit them.
