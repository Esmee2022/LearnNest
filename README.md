# LearnNest

LearnNest is a Montessori-inspired learning platform for children aged 3–7 and their families and educators. The repository now contains a responsive React web client, an Express API, a separate Expo/React Native application, Supabase PostgreSQL migrations, synthetic sample data, and deployment/recovery guides.

## Current implementation status

- **Implemented in code:** role-aware web and mobile shells, parent registration and teacher invitations, opaque sessions, Argon2id password hashing with a unique salt per account and server-only pepper, TOTP enrollment and verification, role checks in API middleware, learning activity browsing and progress recording, append-only hash-chained audit records, encrypted application-data exports, checksum/decryption verification, read-only restore previews, and configuration rollback limited to `ui.*` and `feature.*` settings.
- **Needs configured Supabase and secrets:** database-backed login, cloud activity loading, account invitations, backups, and other database operations. Production uses Supabase PostgreSQL; the application does not use a local database.
- **Recovery distinction:** the button creates an encrypted application-data export. It is not a full PostgreSQL snapshot and does not replace Supabase PITR. The separately confirmed application-data restore replaces learning/business data transactionally while preserving accounts, authentication data, sessions, audit history, configuration and the original backup. Full recovery uses the controlled Supabase PITR workflow described in [docs/recovery.md](docs/recovery.md).
- **External setup required:** configure SMTP, Supabase, Vercel/Render, Expo EAS project/signing, and your production domains. No deployment has been performed from this workspace.

## Quick start

1. Install Node.js 20 or newer.
2. Create a Supabase project. In its SQL editor, apply the files in `supabase/migrations` in filename order. This creates the schema and backup bucket, then removes the legacy data-changing restore RPC so restore points remain read-only previews.
3. In Supabase Storage, create a **private** bucket named `learnnest-backups`.
4. Copy `.env.example` to `.env` in the repository root and set the Supabase project URL and service-role key, a random password pepper, a base64-encoded 32-byte TOTP encryption key, a base64-encoded 32-byte backup encryption key, and a random 32-byte access/session secret. Keep `.env` private.
5. Run `npm install` and `npm run dev` from the repository root.
6. Open the Vite URL shown in the terminal (normally `http://localhost:5173`). The API runs at `http://localhost:4000`.
7. Generate and upload learning activities with `npm run seed:activities` then `npm run seed:cloud-activities`.
8. Optionally set five unique `SEED_*_PASSWORD` values in `.env` and run `npm run seed:demo` for development-only sample accounts. The seed refuses to run when `NODE_ENV=production`.

The `.env` example values are placeholders and will not connect to a database. If Supabase has not been configured, the web shell loads but API-backed sign-in shows a connection/setup error. The root `index.html` now loads the React application; run it using the workspace commands above.

## Useful commands

```powershell
npm install
npm run dev
npm run typecheck
npm test
npm run build
npm run seed:activities
npm run seed:cloud-activities
npm run seed:demo
```

## Project map

| Path | Purpose |
|---|---|
| `apps/web` | React, TypeScript, Vite responsive browser client |
| `apps/api` | Express REST API, authentication, authorization and server-side services |
| `apps/mobile` | Installable Expo / React Native iOS and Android client |
| `packages/shared` | Shared role and activity types |
| `supabase/migrations` | PostgreSQL schema, constraints, indexes, RLS and append-only audit trigger |
| `supabase/seed` | Deterministic generator for 1,000 varied synthetic activity definitions |
| `docs` | Architecture, security, operational, user and admin guides |

## Environment variables

See [.env.example](.env.example). The API requires `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `PASSWORD_PEPPER`, and `TOTP_ENCRYPTION_KEY`. Backup creation additionally requires a private storage bucket and `BACKUP_ENCRYPTION_KEY`. Production account invitation and reset email requires SMTP settings. Configure `WEB_ORIGIN` to the exact allowed web origins; use HTTPS and `COOKIE_SECURE=true` in production.

## Demo accounts

The seed script supports `superadmin@learnnest.test`, `admin@learnnest.test`, `teacher@learnnest.test`, `parent@learnnest.test`, and `child@learnnest.test`. Passwords are read only from local environment variables. No default passwords are committed. Privileged accounts must enroll in TOTP before sensitive operations; save the recovery codes outside the app.

## Guides

- [Architecture and permissions](docs/architecture.md)
- [API reference](docs/api.md)
- [Security operations](docs/security.md)
- [Backup and recovery](docs/recovery.md)
- [Deployment and mobile builds](docs/deployment.md)
- [Parent/teacher/child guide](docs/user-guide.md)
- [Administrator guide](docs/admin-guide.md)
