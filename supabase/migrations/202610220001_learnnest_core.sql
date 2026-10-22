create extension if not exists pgcrypto;
create extension if not exists citext;
create type public.account_status as enum ('active','suspended','deactivated');
create type public.activity_difficulty as enum ('gentle','growing','stretch');

create table public.roles(id uuid primary key default gen_random_uuid(),code text unique not null check(code in ('super_admin','admin','teacher','parent','child')),name text not null,created_at timestamptz not null default now());
create table public.permissions(id uuid primary key default gen_random_uuid(),code text unique not null,name text not null,description text);
create table public.role_permissions(role_id uuid references public.roles on delete cascade,permission_id uuid references public.permissions on delete cascade,primary key(role_id,permission_id));
create table public.users(id uuid primary key default gen_random_uuid(),email citext unique not null,full_name text not null,status public.account_status not null default 'active',school_scope text,created_at timestamptz not null default now(),last_login_at timestamptz,deleted_at timestamptz,check(length(full_name) between 2 and 100));
create table public.user_consents(id uuid primary key default gen_random_uuid(),user_id uuid references public.users on delete cascade,consent_type text not null,granted boolean not null,policy_version text not null,created_at timestamptz not null default now());
create table public.user_roles(user_id uuid references public.users on delete cascade,role_id uuid references public.roles,assigned_by uuid references public.users,assigned_at timestamptz not null default now(),primary key(user_id,role_id));
create table public.user_security(user_id uuid primary key references public.users on delete cascade,password_hash text not null,password_salt text not null,algorithm text not null default 'argon2id',algorithm_parameters jsonb not null,hash_scheme_version integer not null default 1,pepper_version text not null,password_updated_at timestamptz not null default now(),two_factor_enabled boolean not null default false,failed_login_count integer not null default 0,locked_until timestamptz);
create table public.password_demo_hashes(id uuid primary key default gen_random_uuid(),created_by uuid references public.users on delete cascade,password_hash text not null,password_salt text not null,algorithm text not null,algorithm_parameters jsonb not null,pepper_version text not null,expires_at timestamptz not null,created_at timestamptz not null default now());
create table public.totp_credentials(user_id uuid primary key references public.users on delete cascade,encrypted_secret text not null,enabled_at timestamptz,last_verified_step bigint,created_at timestamptz not null default now());
create table public.recovery_codes(id uuid primary key default gen_random_uuid(),user_id uuid references public.users on delete cascade,code_hash text not null,pepper_version text not null,used_at timestamptz,created_at timestamptz not null default now(),unique(user_id,code_hash));
create table public.sessions(id uuid primary key default gen_random_uuid(),user_id uuid references public.users on delete cascade,token_hash text unique not null,expires_at timestamptz not null,revoked_at timestamptz,reauthenticated_at timestamptz,created_at timestamptz not null default now());
create table public.auth_challenges(id uuid primary key default gen_random_uuid(),user_id uuid references public.users on delete cascade,challenge_hash text unique not null,expires_at timestamptz not null,attempts integer not null default 0,used_at timestamptz,created_at timestamptz not null default now());
create table public.password_reset_tokens(id uuid primary key default gen_random_uuid(),user_id uuid references public.users on delete cascade,token_hash text unique not null,expires_at timestamptz not null,used_at timestamptz,created_at timestamptz not null default now());
create table public.user_invitations(id uuid primary key default gen_random_uuid(),email citext not null,full_name text not null,role_id uuid references public.roles,school_scope text,token_hash text unique not null,created_by uuid references public.users on delete set null,expires_at timestamptz not null,used_at timestamptz,created_at timestamptz not null default now());

create table public.children(id uuid primary key default gen_random_uuid(),user_id uuid unique references public.users on delete set null,display_name text not null,age integer not null check(age between 3 and 7),learning_level text not null default 'foundations',created_at timestamptz not null default now(),deleted_at timestamptz);
create table public.parent_child_relationships(parent_user_id uuid references public.users on delete cascade,child_id uuid references public.children on delete cascade,relationship text not null default 'guardian',consent_at timestamptz,primary key(parent_user_id,child_id));
create table public.classes(id uuid primary key default gen_random_uuid(),name text not null,school_scope text,created_by uuid references public.users,created_at timestamptz not null default now());
create table public.teacher_class_assignments(teacher_user_id uuid references public.users on delete cascade,class_id uuid references public.classes on delete cascade,primary key(teacher_user_id,class_id));
create table public.teacher_child_assignments(teacher_user_id uuid references public.users on delete cascade,child_id uuid references public.children on delete cascade,class_id uuid references public.classes on delete set null,primary key(teacher_user_id,child_id));

create table public.learning_activities(id text primary key,title text not null,description text not null,category text not null,min_age integer not null check(min_age between 3 and 7),max_age integer not null check(max_age between min_age and 7),difficulty public.activity_difficulty not null,instructions jsonb not null,objective text not null,activity_type text not null,media text,questions jsonb not null default '[]',completion_criteria text not null,duration_minutes integer not null check(duration_minutes between 1 and 90),accessibility jsonb not null default '[]',published_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.class_activity_assignments(id uuid primary key default gen_random_uuid(),class_id uuid references public.classes on delete cascade,activity_id text references public.learning_activities on delete cascade,assigned_by uuid references public.users on delete set null,due_at timestamptz,note text,created_at timestamptz not null default now(),unique(class_id,activity_id));
create table public.activity_questions(id uuid primary key default gen_random_uuid(),activity_id text references public.learning_activities on delete cascade,question_order integer not null,prompt text not null,choices jsonb not null default '[]',answer text not null,unique(activity_id,question_order));
create table public.activity_attempts(id uuid primary key default gen_random_uuid(),child_id uuid references public.children on delete cascade,activity_id text references public.learning_activities,completed boolean not null default false,score numeric(5,2) check(score between 0 and 100),duration_seconds integer not null check(duration_seconds between 0 and 7200),created_by uuid references public.users,created_at timestamptz not null default now());
create table public.learning_progress(id uuid primary key default gen_random_uuid(),child_id uuid references public.children on delete cascade,activity_id text references public.learning_activities,status text not null check(status in ('started','completed','favorite')),updated_at timestamptz not null default now(),unique(child_id,activity_id,status));
create table public.achievements(id uuid primary key default gen_random_uuid(),code text unique not null,title text not null,description text not null,icon text not null default '🌱');
create table public.child_achievements(child_id uuid references public.children on delete cascade,achievement_id uuid references public.achievements on delete cascade,earned_at timestamptz not null default now(),primary key(child_id,achievement_id));
create table public.user_favorites(user_id uuid references public.users on delete cascade,activity_id text references public.learning_activities on delete cascade,created_at timestamptz not null default now(),primary key(user_id,activity_id));
create table public.teacher_notes(id uuid primary key default gen_random_uuid(),teacher_user_id uuid references public.users on delete set null,child_id uuid references public.children on delete cascade,note text not null check(length(note)<=2000),created_at timestamptz not null default now());

create table public.audit_logs(id uuid primary key default gen_random_uuid(),event_type text not null,actor_user_id uuid references public.users on delete set null,target_resource_id text,outcome text not null check(outcome in ('success','failure','denied')),reason text,metadata jsonb not null default '{}',request_id text,created_at timestamptz not null default now(),previous_hash text not null,entry_hash text not null);
create table public.deletion_records(id uuid primary key default gen_random_uuid(),user_id uuid,actor_user_id uuid references public.users on delete set null,reason text not null,minimal_identity_hash text not null,created_at timestamptz not null default now());
create table public.backup_records(id uuid primary key default gen_random_uuid(),created_by uuid references public.users on delete set null,backup_type text not null,status text not null,scope jsonb not null,size_bytes bigint,checksum_sha256 text not null,storage_bucket text not null,storage_path text not null,created_at timestamptz not null default now(),retention_expires_at timestamptz,last_verified_at timestamptz,verification_status text);
create table public.restore_records(id uuid primary key default gen_random_uuid(),backup_id uuid references public.backup_records on delete restrict,requested_by uuid references public.users on delete set null,status text not null,mode text not null,reason text not null,created_at timestamptz not null default now(),completed_at timestamptz,result_summary jsonb);
create table public.security_events(id uuid primary key default gen_random_uuid(),event_type text not null,user_id uuid references public.users on delete set null,severity text not null default 'info',metadata jsonb not null default '{}',created_at timestamptz not null default now());
create table public.system_settings(key text primary key,value jsonb not null,updated_by uuid references public.users on delete set null,updated_at timestamptz not null default now());
create table public.configuration_revisions(id uuid primary key default gen_random_uuid(),created_by uuid references public.users on delete set null,settings jsonb not null,reason text not null,created_at timestamptz not null default now());
create table public.consent_records(id uuid primary key default gen_random_uuid(),parent_user_id uuid references public.users on delete cascade,child_id uuid references public.children on delete cascade,consent_type text not null,granted boolean not null,policy_version text not null,created_at timestamptz not null default now());
insert into storage.buckets(id,name,public) values ('learnnest-backups','learnnest-backups',false) on conflict(id) do update set public=false;

create or replace function public.export_application_backup() returns jsonb language sql security definer set search_path=public as $$
  select jsonb_build_object('schemaVersion',1,'createdAt',now(),'tables',jsonb_build_object(
    'users',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,email,full_name,status,school_scope,created_at,last_login_at,deleted_at from users) x),'[]'::jsonb),
    'user_roles',coalesce((select jsonb_agg(to_jsonb(x)) from (select user_id,role_id,assigned_by,assigned_at from user_roles) x),'[]'::jsonb),
    'children',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,user_id,display_name,age,learning_level,created_at,deleted_at from children) x),'[]'::jsonb),
    'parent_child_relationships',coalesce((select jsonb_agg(to_jsonb(x)) from (select parent_user_id,child_id,relationship,consent_at from parent_child_relationships) x),'[]'::jsonb),
    'classes',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,name,school_scope,created_by,created_at from classes) x),'[]'::jsonb),
    'teacher_class_assignments',coalesce((select jsonb_agg(to_jsonb(x)) from (select teacher_user_id,class_id from teacher_class_assignments) x),'[]'::jsonb),
    'teacher_child_assignments',coalesce((select jsonb_agg(to_jsonb(x)) from (select teacher_user_id,child_id,class_id from teacher_child_assignments) x),'[]'::jsonb),
    'learning_activities',coalesce((select jsonb_agg(to_jsonb(x)) from (select * from learning_activities) x),'[]'::jsonb),
    'class_activity_assignments',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,class_id,activity_id,assigned_by,due_at,note,created_at from class_activity_assignments) x),'[]'::jsonb),
    'activity_questions',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,activity_id,question_order,prompt,choices,answer from activity_questions) x),'[]'::jsonb),
    'activity_attempts',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,child_id,activity_id,completed,score,duration_seconds,created_by,created_at from activity_attempts) x),'[]'::jsonb),
    'learning_progress',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,child_id,activity_id,status,updated_at from learning_progress) x),'[]'::jsonb),
    'achievements',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,code,title,description,icon from achievements) x),'[]'::jsonb),
    'child_achievements',coalesce((select jsonb_agg(to_jsonb(x)) from (select child_id,achievement_id,earned_at from child_achievements) x),'[]'::jsonb),
    'user_favorites',coalesce((select jsonb_agg(to_jsonb(x)) from (select user_id,activity_id,created_at from user_favorites) x),'[]'::jsonb),
    'teacher_notes',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,teacher_user_id,child_id,note,created_at from teacher_notes) x),'[]'::jsonb),
    'consent_records',coalesce((select jsonb_agg(to_jsonb(x)) from (select id,parent_user_id,child_id,consent_type,granted,policy_version,created_at from consent_records) x),'[]'::jsonb),
    'system_settings',coalesce((select jsonb_agg(to_jsonb(x)) from (select key,value,updated_by,updated_at from system_settings where key like 'ui.%' or key like 'feature.%') x),'[]'::jsonb)
  ));
$$;
revoke all on function public.export_application_backup() from public,anon,authenticated;
grant execute on function public.export_application_backup() to service_role;

create or replace function public.apply_application_restore(restore_payload jsonb) returns jsonb
language plpgsql security definer set search_path=public as $$
declare t jsonb; restored jsonb;
begin
  if coalesce((restore_payload->>'schemaVersion')::integer,0)<>1 or jsonb_typeof(restore_payload->'tables')<>'object' then raise exception 'Unsupported application backup manifest'; end if;
  t:=restore_payload->'tables';
  perform pg_advisory_xact_lock(hashtext('learnnest.application.restore'));
  delete from public.child_achievements;delete from public.activity_attempts;delete from public.learning_progress;delete from public.user_favorites;delete from public.teacher_notes;delete from public.class_activity_assignments;delete from public.teacher_child_assignments;delete from public.teacher_class_assignments;delete from public.parent_child_relationships;delete from public.consent_records;delete from public.activity_questions;delete from public.children;delete from public.classes;delete from public.learning_activities;delete from public.achievements;
  insert into public.learning_activities select x.* from jsonb_populate_recordset(null::public.learning_activities,t->'learning_activities') x;
  insert into public.activity_questions select x.* from jsonb_populate_recordset(null::public.activity_questions,t->'activity_questions') x;
  insert into public.achievements select x.* from jsonb_populate_recordset(null::public.achievements,t->'achievements') x;
  insert into public.classes select x.* from jsonb_populate_recordset(null::public.classes,t->'classes') x where x.created_by is null or exists(select 1 from public.users u where u.id=x.created_by);
  insert into public.children select x.* from jsonb_populate_recordset(null::public.children,t->'children') x where x.user_id is null or exists(select 1 from public.users u where u.id=x.user_id);
  insert into public.teacher_class_assignments select x.* from jsonb_populate_recordset(null::public.teacher_class_assignments,t->'teacher_class_assignments') x where exists(select 1 from public.users u where u.id=x.teacher_user_id) and exists(select 1 from public.classes c where c.id=x.class_id);
  insert into public.parent_child_relationships select x.* from jsonb_populate_recordset(null::public.parent_child_relationships,t->'parent_child_relationships') x where exists(select 1 from public.users u where u.id=x.parent_user_id) and exists(select 1 from public.children c where c.id=x.child_id);
  insert into public.teacher_child_assignments select x.* from jsonb_populate_recordset(null::public.teacher_child_assignments,t->'teacher_child_assignments') x where exists(select 1 from public.users u where u.id=x.teacher_user_id) and exists(select 1 from public.children c where c.id=x.child_id) and (x.class_id is null or exists(select 1 from public.classes c where c.id=x.class_id));
  insert into public.class_activity_assignments select x.* from jsonb_populate_recordset(null::public.class_activity_assignments,t->'class_activity_assignments') x where exists(select 1 from public.classes c where c.id=x.class_id) and exists(select 1 from public.learning_activities a where a.id=x.activity_id) and (x.assigned_by is null or exists(select 1 from public.users u where u.id=x.assigned_by));
  insert into public.activity_attempts select x.* from jsonb_populate_recordset(null::public.activity_attempts,t->'activity_attempts') x where exists(select 1 from public.children c where c.id=x.child_id) and exists(select 1 from public.learning_activities a where a.id=x.activity_id) and (x.created_by is null or exists(select 1 from public.users u where u.id=x.created_by));
  insert into public.learning_progress select x.* from jsonb_populate_recordset(null::public.learning_progress,t->'learning_progress') x where exists(select 1 from public.children c where c.id=x.child_id) and exists(select 1 from public.learning_activities a where a.id=x.activity_id);
  insert into public.child_achievements select x.* from jsonb_populate_recordset(null::public.child_achievements,t->'child_achievements') x where exists(select 1 from public.children c where c.id=x.child_id) and exists(select 1 from public.achievements a where a.id=x.achievement_id);
  insert into public.user_favorites select x.* from jsonb_populate_recordset(null::public.user_favorites,t->'user_favorites') x where exists(select 1 from public.users u where u.id=x.user_id) and exists(select 1 from public.learning_activities a where a.id=x.activity_id);
  insert into public.teacher_notes select x.* from jsonb_populate_recordset(null::public.teacher_notes,t->'teacher_notes') x where (x.teacher_user_id is null or exists(select 1 from public.users u where u.id=x.teacher_user_id)) and exists(select 1 from public.children c where c.id=x.child_id);
  insert into public.consent_records select x.* from jsonb_populate_recordset(null::public.consent_records,t->'consent_records') x where exists(select 1 from public.users u where u.id=x.parent_user_id) and exists(select 1 from public.children c where c.id=x.child_id);
  restored:=jsonb_build_object('activities',(select count(*) from public.learning_activities),'children',(select count(*) from public.children),'attempts',(select count(*) from public.activity_attempts),'classes',(select count(*) from public.classes));
  return restored;
end $$;
revoke all on function public.apply_application_restore(jsonb) from public,anon,authenticated;
grant execute on function public.apply_application_restore(jsonb) to service_role;

create index users_status_created_idx on public.users(status,created_at desc) where deleted_at is null;
create index sessions_user_expiry_idx on public.sessions(user_id,expires_at);
create index activity_age_category_idx on public.learning_activities(category,min_age,max_age) where published_at is not null;
create index attempts_child_created_idx on public.activity_attempts(child_id,created_at desc);
create index audit_created_idx on public.audit_logs(created_at desc);
create index audit_actor_idx on public.audit_logs(actor_user_id,created_at desc);
create index security_event_created_idx on public.security_events(created_at desc);

insert into public.roles(code,name) values ('super_admin','Super Administrator'),('admin','Administrator'),('teacher','Teacher / Manager'),('parent','Parent / Guardian'),('child','Child Learner') on conflict(code) do nothing;
insert into public.permissions(code,name) values
('users.read','View scoped users'),('users.manage','Manage scoped users'),('users.roles.manage','Assign roles'),('audit.read','View audit log'),('security.read','View security events'),('backup.create','Create backups'),('restore.execute','Execute recovery'),('content.manage','Manage learning content'),('classes.manage','Manage classes'),('progress.read','View authorized progress'),('progress.write','Record learning progress'),('children.manage','Manage linked child profiles'),('config.manage','Manage system settings') on conflict(code) do nothing;
insert into public.role_permissions(role_id,permission_id)
select r.id,p.id from public.roles r join public.permissions p on
 (r.code='super_admin') or
 (r.code='admin' and p.code in ('users.read','users.manage','audit.read','security.read','backup.create','content.manage','classes.manage','progress.read')) or
 (r.code='teacher' and p.code in ('classes.manage','progress.read','progress.write')) or
 (r.code='parent' and p.code in ('children.manage','progress.read','progress.write')) or
 (r.code='child' and p.code in ('progress.read','progress.write')) on conflict do nothing;
insert into public.achievements(code,title,description,icon) values
('first_steps','First Steps','You tried your first learning activity.','🌱'),('curious_explorer','Curious Explorer','You explored five learning activities.','🧭'),('careful_counter','Careful Counter','You practiced numbers and counting.','🔢'),('nature_friend','Nature Friend','You learned something about the natural world.','🦋') on conflict(code) do nothing;

create or replace function public.reject_audit_mutation() returns trigger language plpgsql as $$ begin raise exception 'audit log entries are append-only'; end $$;
create trigger audit_logs_append_only before update or delete on public.audit_logs for each row execute function public.reject_audit_mutation();
create or replace function public.reject_audit_truncate() returns trigger language plpgsql as $$ begin raise exception 'audit log entries are append-only'; end $$;
create trigger audit_logs_no_truncate before truncate on public.audit_logs for each statement execute function public.reject_audit_truncate();
create or replace function public.chain_audit_insert() returns trigger language plpgsql as $$
declare prior text; body text;
begin
 perform pg_advisory_xact_lock(hashtext('learnnest.audit.chain'));
 select entry_hash into prior from public.audit_logs order by created_at desc,id desc limit 1;
 new.previous_hash:=coalesce(prior,'GENESIS');
 body:=(to_jsonb(new)-'previous_hash'-'entry_hash')::text;
 new.entry_hash:=encode(digest(new.previous_hash||body,'sha256'),'hex');
 return new;
end $$;
create trigger audit_logs_chain_insert before insert on public.audit_logs for each row execute function public.chain_audit_insert();

do $$ declare t record; begin for t in select tablename from pg_tables where schemaname='public' loop execute format('alter table public.%I enable row level security',t.tablename); execute format('revoke all on public.%I from anon,authenticated',t.tablename); end loop; end $$;
grant select on public.learning_activities to anon,authenticated;
create policy "published activities are readable" on public.learning_activities for select to anon,authenticated using (published_at is not null);
create policy "users read own profile" on public.users for select to authenticated using (id=auth.uid());
create policy "children through parent link" on public.children for select to authenticated using (exists(select 1 from public.parent_child_relationships p where p.child_id=id and p.parent_user_id=auth.uid()));
create policy "parents manage own links" on public.parent_child_relationships for select to authenticated using (parent_user_id=auth.uid());
create policy "attempts through parent link" on public.activity_attempts for select to authenticated using (exists(select 1 from public.parent_child_relationships p where p.child_id=child_id and p.parent_user_id=auth.uid()));
create policy "progress through parent link" on public.learning_progress for select to authenticated using (exists(select 1 from public.parent_child_relationships p where p.child_id=child_id and p.parent_user_id=auth.uid()));
create policy "favorites are private" on public.user_favorites for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "consent by parent" on public.consent_records for select to authenticated using(parent_user_id=auth.uid());

comment on table public.audit_logs is 'Append-only application audit trail with hash chaining; service-role maintenance is restricted and separately audited.';
comment on table public.user_security is 'Authentication metadata only; password pepper is managed outside the database.';
comment on table public.backup_records is 'Encrypted object-storage application exports; not a substitute for Supabase PITR/full physical backup.';
