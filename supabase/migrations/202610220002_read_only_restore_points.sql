-- Restore points in the application are read-only previews. Configuration
-- rollback is limited separately to ui.* and feature.* settings.
revoke all on function public.apply_application_restore(jsonb)
  from public, anon, authenticated, service_role;
drop function public.apply_application_restore(jsonb);
