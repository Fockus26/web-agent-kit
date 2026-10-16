# Phase 07 — Backend

## Goal

The functionality: authentication, sessions, persistence, real forms, payments.

Run by `backend-build`.

## Scope

- Data model and migrations (in `supabase/migrations/`, in git).
- Authentication: sign-up, login, session, logout, password recovery.
- Authorization: route protection **on the server**.
- User data persistence.
- Forms with server validation (shared zod schema).
- Payment gateway: checkout, idempotent webhooks with verified signature.
- Environment variables documented in `.env.example`.

## Inputs

`context/PROJECT_CONTEXT.md` (decided external services) · the UI contract the frontend
expects · phases 01-06 closed

## Units of work

1. Data model and connection
1b. Emails: `EmailLayout`, sending provider (decision) and auth templates in
    `supabase/templates/` (before sign-up, which already sends the first one) — only if
    `PROJECT_CONTEXT.md` § "Emails" applies
2. Auth: sign-up and login
3. Auth: session, route protection, logout
4. Auth: password recovery
5. {{The project's domain: products, orders, bookings…}}
6. Payments: checkout
7. Payments: webhooks and confirmation
8. Contact forms / email sending (with their acknowledgment and notice emails)

Emails follow the kit's `reference/EMAIL-TEMPLATES.md` and the design in
`design/HANDOFF.md` § 5c: each transactional email goes in the unit of the flow that sends it.

## Closing criteria

- [ ] Zero secrets in the code; `.env.example` complete and without real values.
- [ ] Server validation on every input.
- [ ] Routes protected on the server, not just hidden in the UI.
- [ ] The price is computed on the server; the client's amount is never trusted.
- [ ] Webhooks with verified signature and idempotent.
- [ ] UI contract documented for the frontend.
- [ ] Emails: closing criteria of `reference/EMAIL-TEMPLATES.md` met (if it applies).
- [ ] `functional-qa` launched when each full flow closes, and its critical findings resolved.
- [ ] César's manual actions documented with exact steps.
