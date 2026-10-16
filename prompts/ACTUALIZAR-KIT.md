# Update a project to the latest kit version

(Kept under its old Spanish name because projects before 3.6.0 cite it in their `CLAUDE.md`.)

Since 3.6.0 this is done by the **`kit-update`** skill; this prompt is no longer pasted. What
it did (computing the path with `UPDATES.md` and applying it on a branch and a PR, one commit
per version) now lives in `.claude/skills/kit-update/SKILL.md`, together with the version
comparison against the published kit.

1. Install the kit on the machine (once, and every time you want to bring in what is new):

   ```powershell
   powershell -ExecutionPolicy Bypass -File "<kit path>\install-kit.ps1" -Pull
   ```

2. Open a **new** Claude Code session in the project's folder and type:

   ```
   /kit-update
   ```

It compares the project's version (`.kit-version`), the installed skills' version and the
kit's `origin/main`. If they match, it says it is up to date and checks for missing pieces;
if the skills are old, it reinstalls them and asks for another session; if the project is
behind, it updates it in a PR.
