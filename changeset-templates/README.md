# Changesets

Every PR that changes something **the person using the site notices** adds a file here,
`<kebab-case-description>.md` (unique name, e.g. `repetir-combinacion.md`):

```md
---
"<name from package.json>": minor
---

Ahora puedes repetir una combinación desde el historial.
```

- **patch**: a fix. **minor**: a new feature. **major**: breaks stored data or removes something.
- The text is user-facing, in the site's language: what they can do now or what stopped
  failing, not which file changed.
- Docs, tests, CI and refactors: no changeset.
- Nobody touches `version` or `CHANGELOG.md` by hand. The `release.yml` Action keeps a
  "chore(release): versión" PR open that gathers the changesets, bumps the version and writes
  the CHANGELOG. A version is published when that PR is merged.

`bun x changeset` does the same with questions; agents write the file by hand.
