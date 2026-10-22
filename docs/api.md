# REST API reference

Base URL: `/api`. JSON requests/responses. Web requests use HTTP-only cookies; native requests send `Authorization: Bearer <session>` and `X-Client: mobile`. Errors use `{ "error": "…", "requestId": "…" }`. Zod validation rejects malformed inputs. `X-Request-Id` is echoed for support. Login, 2FA and signup routes are rate limited.

## Authentication

| Method/path | Access | Purpose |
|---|---|---|
| `POST /auth/signup` | Public | Create a parent/guardian account; consent required |
| `POST /auth/accept-invite` | Public, one-time token | Set a password for a school invitation |
| `POST /auth/login` | Public | Password factor; returns short-lived 2FA challenge when enabled |
| `POST /auth/verify-2fa` | Public, challenge token | Complete login with TOTP or one-time recovery code |
| `POST /auth/recovery-code` | Public, challenge token | Recovery-code alias for the 2FA verifier |
| `POST /auth/logout` | Session | Revoke current session |
| `POST /auth/refresh` | Session | Rotate session token and revoke previous session |
| `GET /auth/me` | Session | Current account and role; never returns secrets |
| `POST /auth/forgot-password` | Public | Request reset email (generic response) |
| `POST /auth/reset-password` | One-time reset token | Reset password and revoke sessions |
| `POST /auth/2fa/enroll` | Session | Start authenticator enrollment; secret is returned only for setup |
| `POST /auth/2fa/confirm` | Session | Confirm enrollment; recovery codes shown once |
| `POST /auth/2fa/disable` | Session + current TOTP | Disable factor and revoke other sessions |

## Accounts, learning, and audit

`GET /roles`, `GET /users?page=&limit=&search=&status=`, `GET /users/:id`, `POST /users` (invite), `PATCH /users/:id` (status), `PATCH /users/:id/roles` (super-admin plus recent MFA), and `DELETE /users/:id` (soft delete plus deletion record). Administrator account operations are filtered to their assigned `school_scope`; an administrator without a scope is denied. Administrator writes require fresh TOTP. Children endpoints are `GET /children`, `POST /children` (linked guardian with recorded consent), `GET /children/:id/progress`, and `POST /children/:id/progress`. Teachers and parents are checked against assignment/link records.

Published activities: `GET /activities?page=&limit=&category=&age=`, `GET /activities/:id`, and authenticated `POST /activities/:id/attempts`. Public activity responses omit correct answers. `GET /reports/learning` is limited to administrators and teachers, with teacher results scoped to assigned children.

Audit/security: `GET /audit-logs` and `GET /security-events` are admin/super-admin only. Audit writes are append-only in PostgreSQL and hash chained with a serialized trigger. No API permits editing/deleting audit rows.

## Backups

`POST /backups`, `GET /backups`, `GET /backups/:id`, `POST /backups/:id/verify`, `POST /restores`, `GET /restores`, and `GET /restores/:id`. Creating/verifying backups and requesting restores need appropriate role and recent 2FA. A restore request body includes `backupId`, `confirmation: "RESTORE"`, a reason, and mode (`preview` or `application-data`). Preview does not modify data. Application-data restore verifies checksum and authenticated decryption, checks the manifest version, then invokes one transactional PostgreSQL function to replace the allow-listed learning/business tables. Accounts, roles, authentication/security data, sessions, audit history, configuration, and the source restore point are preserved. Full PostgreSQL recovery remains a separate Supabase PITR workflow.

`POST /configuration` snapshots the current `ui.*`/`feature.*` settings then applies an allow-listed settings map. `GET /configuration` and `GET /configuration/revisions` review configuration. `POST /configuration/rollback` accepts a revision id, explicit confirmation and reason, and restores only those nonfunctional settings; it is not a business-data restore. `GET /health` is a liveness/configuration check and does not disclose secrets.
