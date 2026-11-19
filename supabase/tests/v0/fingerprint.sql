-- Deterministic schema fingerprint of the V0 objects (structure, privileges, policies, buckets).
-- Equal output after two clean rebuilds, or after legacy->teardown->baseline, proves reproducibility.
with parts(k, v) as (
  select 'schema_owner', string_agg(nspname || '=' || pg_get_userbyid(nspowner)::text || ':' || coalesce(nspacl::text, ''), '|' order by nspname) from pg_namespace where nspname in ('public', 'private')
  union all select 'columns', string_agg(format('%s.%s %s %s %s', c.relname, a.attname, format_type(a.atttypid, a.atttypmod), a.attnotnull, coalesce(pg_get_expr(d.adbin, d.adrelid), '')), '|' order by c.relname, a.attnum)
    from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public'
    join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
    left join pg_attrdef d on d.adrelid = c.oid and d.adnum = a.attnum where c.relkind = 'r'
  union all select 'constraints', string_agg(format('%s %s %s', conrelid::regclass, conname, pg_get_constraintdef(oid)), '|' order by conrelid::regclass::text, conname)
    from pg_constraint where connamespace = 'public'::regnamespace
  union all select 'indexes', string_agg(indexdef, '|' order by indexname) from pg_indexes where schemaname = 'public'
  union all select 'rls', string_agg(format('%s:%s', relname, relrowsecurity), '|' order by relname)
    from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public' where relkind = 'r'
  union all select 'policies', string_agg(format('%s %s %s %s %s %s', tablename, policyname, cmd, roles, qual, with_check), '|' order by tablename, policyname)
    from pg_policies where schemaname in ('public', 'storage')
  union all select 'functions', string_agg(pg_get_functiondef(p.oid) || coalesce(p.proacl::text, ''), '|' order by p.proname, p.oid::regprocedure::text)
    from pg_proc p join pg_namespace pn on pn.oid = p.pronamespace where pn.nspname in ('public', 'private')
  union all select 'triggers', string_agg(pg_get_triggerdef(t.oid), '|' order by t.tgname)
    from pg_trigger t join pg_class c on c.oid = t.tgrelid join pg_namespace n on n.oid = c.relnamespace
   where not t.tgisinternal and (n.nspname = 'public' or (n.nspname = 'auth' and c.relname = 'users'))
  union all select 'table_acl', string_agg(format('%s %s', c.relname, coalesce(c.relacl::text, '')), '|' order by c.relname)
    from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public' where relkind = 'r'
  union all select 'column_acl', string_agg(format('%s.%s %s', c.relname, a.attname, a.attacl), '|' order by c.relname, a.attname)
    from pg_attribute a join pg_class c on c.oid = a.attrelid join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'public' where a.attacl is not null
  union all select 'types', string_agg(format('%s %s', t.typname, (select string_agg(enumlabel, ',' order by enumsortorder) from pg_enum e where e.enumtypid = t.oid)), '|' order by t.typname)
    from pg_type t where t.typnamespace = 'public'::regnamespace and t.typtype = 'e'
  union all select 'default_acl', string_agg(format('%s %s %s', defaclrole::regrole, defaclobjtype, defaclacl), '|' order by defaclrole::regrole::text, defaclobjtype)
    from pg_default_acl where defaclrole = 'postgres'::regrole and (defaclnamespace = 'public'::regnamespace or defaclnamespace = 0)
    -- supabase_admin's own default ACLs in public cannot be altered by postgres (see CLAUDE_PROGRESS finding R-1)
  union all select 'buckets', string_agg(format('%s %s %s %s', id, public, file_size_limit, allowed_mime_types), '|' order by id)
    from storage.buckets where id in ('course-files', 'submission-files')
)
select k, md5(coalesce(v, '')) as md5 from parts
union all select 'ALL', md5(string_agg(k || coalesce(v, ''), '|' order by k)) from parts
order by 1;
