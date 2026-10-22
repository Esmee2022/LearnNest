# Administrator guide

## First setup

Apply the Supabase migration, configure secrets and SMTP, and load activities. To create the first production super-admin, deploy the API, then temporarily set a random `INITIAL_SUPER_ADMIN_SETUP_TOKEN` (at least 32 characters) in the `learnnest-api` Render service environment and redeploy. Call `POST /api/setup/initial-super-admin` with that token in the `x-super-admin-setup-token` header and `{ "email": "admin@gmail.com", "password": "your-new-password" }` as the JSON body. The endpoint only creates this fixed email, refuses if a super-admin already exists, rate-limits attempts, and hashes the password using the hosted API's pepper. Remove `INITIAL_SUPER_ADMIN_SETUP_TOKEN` from Render immediately after it succeeds. Never put the password or token in source control or share them in chat. The sample seed is development-only. Sign in, open **Security**, enroll a TOTP authenticator, and store the recovery codes securely. Do not use the development sample accounts in production.

## People and permissions

The People page shows account role/status, recent sign-in, 2FA state, and password hashing algorithm metadata. It never exposes password hashes, salts, or peppers. Invitations are role-limited, one-time, and expire after 72 hours. Administrators can view and manage users in their assigned school scope, invite teachers, and delete users in that scope; they cannot create another administrator or change roles. Super administrators can view all users and assign roles. Sensitive operations need a recently verified 2FA session and a reason. User deletion anonymizes the profile, revokes sessions, erases password/2FA credentials, and preserves a minimal deletion record and append-only audit event.

The native mobile app has a separate administrator dashboard with a scoped user directory, teacher invitations, and audited user deletion. Its administrative mutations also require a recently verified 2FA session.

## Audit, security and backups

Audit events are append-only; review both event type and outcome. Never ask users to send passwords, MFA tokens, or recovery codes. The backup view creates and verifies encrypted application exports; full recovery uses Supabase PITR and the recovery runbook. A preview restore is a recorded request and does not modify production data. Configuration settings should not contain secrets.

## Content and child privacy

Activities are generated with draft/publication metadata and age bands. Review and publish content before production if school-specific curriculum approval is required. Only collect the child profile details needed for learning; set local retention and deletion periods before onboarding real families.
