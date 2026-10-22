# Administrator guide

## First setup

Apply the Supabase migration, configure secrets and SMTP, load activities, then create the first super-admin through a controlled seed/setup run. The sample seed is development-only and requires five separate environment passwords. Sign in, open **Security**, enroll a TOTP authenticator, and store the recovery codes securely. Do not use the development sample accounts in production.

## People and permissions

The People page shows account role/status, recent sign-in, and whether 2FA is enabled. Invitations are role-limited, one-time, and expire after 72 hours. Administrators can manage only accounts in their assigned school scope; they cannot create another administrator or change roles. Only a super administrator can assign roles, request restore operations, edit system settings, or create global backups. Sensitive operations need a recently verified 2FA session and a reason. User deletion soft-deactivates and anonymizes the profile while preserving the deletion record and audit history.

## Audit, security and backups

Audit events are append-only; review both event type and outcome. Never ask users to send passwords, MFA tokens, or recovery codes. The backup view creates and verifies encrypted application exports; full recovery uses Supabase PITR and the recovery runbook. A preview restore is a recorded request and does not modify production data. Configuration settings should not contain secrets.

## Content and child privacy

Activities are generated with draft/publication metadata and age bands. Review and publish content before production if school-specific curriculum approval is required. Only collect the child profile details needed for learning; set local retention and deletion periods before onboarding real families.
