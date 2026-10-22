# Backup, restore and configuration rollback runbook

## Application-data exports

1. Create a **private** Supabase Storage bucket named `learnnest-backups`; public access must remain disabled.
2. Configure `BACKUP_ENCRYPTION_KEY` as base64 for 32 random bytes and `BACKUP_STORAGE_BUCKET`.
3. A super administrator or permitted administrator enrolls and confirms TOTP, then uses **Create Backup**. The API exports an allow-list of business/application tables, encrypts the payload with AES-256-GCM, uploads an immutable new object, stores the object path/checksum/scope/retention date, and appends an audit event.
4. Click **Verify** or call `POST /api/backups/:id/verify`. This checks the downloaded artifact's SHA-256, authenticates/decrypts it, and parses its manifest. An upload alone is not marked verified. This is integrity/decryption validation, not a test restore into PostgreSQL.
5. Retention is currently 90 days in the application record. Configure a Supabase lifecycle rule to expire old objects; do not delete records before their objects according to retention policy.

## Full database recovery

Application exports omit passwords, password hashes, TOTP credentials, sessions, audit records, and several operational tables; they are not complete snapshots. For full recovery, use Supabase managed PITR or a vetted encrypted `pg_dump` into a separate recovery project, validate migrations and data, then follow the organization's change-control/cutover plan. Restore to a separate database first. Record operator, source point, checksum, validation, impact, and cutover in the incident record. Preserve the immutable source object and add a restore record; never overwrite it.

Restore points are read-only previews: they show snapshot time, scope, status, and checksum, and record the preview in the audit trail. They never overwrite or remove application data. Configuration rollback is a separate operation and is restricted to `ui.*` and `feature.*` settings; it records a revision and requires recent TOTP verification. The immutable encrypted source file is never changed.

The legacy application-data restore RPC is removed by migration `202610220002_read_only_restore_points.sql`. Apply this migration to existing Supabase projects so the deployed database matches the preview-only application behavior. Full database recovery remains a separate Supabase PITR or vetted recovery-project procedure, outside the application's restore-point controls.

## Configuration rollback

Configuration changes affect only selected keys in `system_settings`, leaving account and learning data untouched. Require a fresh TOTP session and a reason, capture current values before change, and review the resulting audit event. Keep the change allow-list limited to non-secret presentation/feature settings; never put secrets in settings or application exports. Configuration rollback is different from restoring a historical database snapshot.

## Recovery objectives and checks

Set RPO/RTO with the school before production. Configure Supabase PITR retention to meet RPO, and test a full restore into a staging project at least quarterly. Verify sign-in/2FA, role boundaries, parent-child separation, activity retrieval, progress, and audit continuity before reopening access. The recovery test checklist is documented; it has not been run without a configured cloud project.
