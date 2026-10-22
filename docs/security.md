# Security operations

## Required production configuration

- HTTPS-only origins, `COOKIE_SECURE=true`, restrictive `WEB_ORIGIN`, and a managed secret vault for every key.
- Use separate random values for `PASSWORD_PEPPER`, `TOTP_ENCRYPTION_KEY`, `BACKUP_ENCRYPTION_KEY`, Supabase service-role key, SMTP credentials, and deployment tokens. TOTP and backup encryption keys must decode to exactly 32 bytes.
- Rotate secrets with a documented version transition. `pepper_version` is recorded per account. Pepper rotation requires a migration strategy: verify using the previous version and rehash on successful sign-in before removing the old secret.
- Keep Supabase service-role and direct database credentials server-side. Prefer a restricted maintenance credential for restore procedures.
- Configure SMTP for account invitations and password reset. Reset tokens expire after 30 minutes and are stored only as keyed digests; invitation tokens expire after 72 hours.

## Authentication and account protection

Passwords require at least 12 characters. Argon2id is slow and memory-hard; the unique salt and pepper prevent reuse/precomputation. Login uses a 5-failure, 15-minute account lock in addition to per-IP request rate limits. TOTP challenges expire in five minutes and allow up to five attempts. Recovery tokens are single-use. Privileged data changes require TOTP verification within the last 10 minutes. Never add a route that returns credential metadata to a parent, teacher, or child.

## Audit and child privacy

Audit events are minimized, UTC-stamped, request-correlated, hash chained in a serialized database trigger, and immutable to ordinary SQL/API updates. Do not record passwords, MFA codes, recovery codes, raw sessions, or reset URLs. Child profile collection is limited to a display name, age/learning level, guardian relationship, consent, and learning data; no public profiles or ad trackers are used. Apply a documented retention schedule before production and obtain qualified privacy/legal review for each operating jurisdiction. This project does not claim legal compliance.

## Current gaps requiring production hardening

- Service-role API requests bypass Postgres RLS by design. Keep explicit API ownership checks, restrict the key to the API service, and consider a dedicated database role/RPC layer before storing real child data.
- SMTP, secret manager, cloud buckets, Supabase RLS review, domain allow-list, security monitoring and retention jobs need production configuration.
- Automated tests currently cover crypto primitives, server role middleware, and activity catalog structure; database-backed authorization, full 2FA, restore and end-to-end cases require a configured isolated Supabase project.
- Account signup is parent/guardian-only. Email addresses are not verified during self-registration; configure and add an address-verification step before accepting real family data.
