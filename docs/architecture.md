# Architecture and access model

## Request path

```text
Web (React/Vite) ─┐
                  ├─ HTTPS REST ─ Express API ─ Supabase PostgreSQL + private Storage
Expo mobile ──────┘                         └─ SMTP (invitation and reset links)
```

The API is the authorization boundary. The browser and native app never receive a Supabase service-role key, pepper, TOTP encryption key, or backup key. Web sessions use an HTTP-only, SameSite=Lax cookie. The native client sends its opaque session as a bearer value and stores it in Expo SecureStore. Database rows contain a keyed digest of the session value. Sessions expire after 12 hours and can be explicitly refreshed (rotation revokes the prior session) or revoked at logout.

The API uses Supabase's server-side service role to execute its own policy-checked operations. Database RLS is enabled and direct anonymous/authenticated table grants are revoked except published activity reads. RLS policies are a defense for direct Supabase clients; because the service role bypasses RLS, all API endpoints must retain explicit server-side ownership checks. The service-role key must never be exposed to either client.

## Roles and permissions

| Role | User/account scope | Learning data | Security and recovery |
|---|---|---|---|
| Super Administrator | All accounts; status and role management | All platform learning data | Audit/security view; TOTP-protected role change/deletion/backup/restore/config actions |
| Administrator | Account list and status management inside assigned school scope; cannot assign own role or create another admin | Content and reports within assigned school scope | Scoped audit/security view; no restore, config, or global backup access |
| Teacher | Assigned class/child records only | Assigned activity/progress/notes | No password metadata, secrets, backup, or unrestricted user access |
| Parent/Guardian | Own account and linked children | Linked child profiles and progress | Own consent/preferences; no admin data |
| Child Learner | Own child profile | Age-appropriate published learning and own attempts | No admin, audit, backup, or account security panels |

The current web interface exposes menus according to role for usability, but the API independently checks each role, administrator school scope, and child relationship. New routes must use `requireAuth`, `allowRoles`, and explicit scope checks. Destructive/sensitive endpoints require a recently verified 2FA session.

## Password and second-factor design

Passwords are HMAC-SHA-256 pre-hashed with a server-side pepper and a domain-separation string, then hashed using Argon2id (19 MiB memory, 2 iterations, 1 lane, 32-byte output) and a unique cryptographically generated 16-byte salt. The salt and Argon2 encoded hash are stored with algorithm/scheme metadata. The pepper is configured outside PostgreSQL. TOTP secrets are encrypted with AES-256-GCM and a separate environment key. Recovery codes are stored only as HMAC digests and are single-use. Never put credentials, reset links, session tokens, TOTP codes, or peppers in logs.

## Data relationships

Users have a role through `user_roles`. Parents link to children using `parent_child_relationships`; teachers receive explicit `teacher_class_assignments` and `teacher_child_assignments`. Attempts reference both child and activity. Sensitive identity/session/security rows are separated. Audit and deletion records remain after account soft deletion. Activity definitions are independent of a learner and can be public only after publication.

## Recovery design

The application backup is a consistent single-statement PostgreSQL export of an allow-listed set of business tables, encrypted with AES-256-GCM and stored in a private Supabase bucket. Security tables, credentials, TOTP data, and sessions are excluded. SHA-256 plus authenticated decryption checks detect corrupt data. These exports are **not full database snapshots**. Use Supabase PITR/managed backups for full recovery. Application-data restoration is a transactional PostgreSQL operation that preserves current authentication and audit data and never overwrites the source artifact. Configuration rollback is separate from business-data restoration.
