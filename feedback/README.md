# feedback/

Feedback reports from the projects, one per file: `<YYYY-MM-DD>-<project>.md` (written in
Spanish, like everything César reads).

They arrive as PRs with the `kit-feedback` label, opened by the `kit-feedback` skill from a
project session. They are processed in a session opened in the kit ("revisa el feedback";
see `CLAUDE.md`): consolidated triage across projects, César chooses, it is implemented in
its own PR, and each feedback PR gets a comment with what went in and what did not before
being merged.

Once merged they stay here as history: when a point arrives again, `grep` for what was
decided the previous time.

This folder is not copied to any project and `install-kit` does not install it.
