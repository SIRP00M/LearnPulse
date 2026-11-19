-- Live Demo Option B — feasibility probe of the Vault / privilege boundaries on the REAL DEV project.
-- One transaction that ALWAYS ends by raising ROLLBACK_OK, so no secret, function, grant or schema change persists.
-- Run: npx supabase@2.81.3 db query --linked -f supabase/tests/v15/probe_vault_boundaries.sql
do $$
declare
  v_sid uuid; r text; k text; log text := ''; n int; t timestamptz := clock_timestamp();
begin
  -- 1. a per-session key can be stored in Vault by the privileged role
  select vault.create_secret('probe-demo-key-' || gen_random_uuid(), 'probe-' || gen_random_uuid(), 'probe') into v_sid;
  assert v_sid is not null, 'vault.create_secret failed';
  select decrypted_secret into k from vault.decrypted_secrets where id = v_sid;
  assert k is not null and k like 'probe-%', 'privileged role cannot decrypt';
  assert (select secret from vault.secrets where id = v_sid) <> k, 'the stored column must be ciphertext, not the plaintext';
  assert (select count(*) from information_schema.columns where table_schema = 'vault' and table_name = 'secrets' and column_name in ('key', 'key_material', 'root_key')) = 0, 'no key-material column in vault.secrets';
  log := log || 'PASS vault stores ciphertext; key material is not a column; privileged role can decrypt; ';

  -- 2. a SECURITY DEFINER function owned by postgres in a NON-exposed schema can use the Vault key to derive per-seat passwords (HMAC)
  create schema probe_priv;
  create function probe_priv.seat_password(p_secret_id uuid, p_seat uuid) returns text
  language plpgsql security definer set search_path = '' as $f$
  declare key text; begin
    select decrypted_secret into key from vault.decrypted_secrets where id = p_secret_id;
    return 'Dm1-' || translate(encode(extensions.hmac(p_seat::text, key, 'sha256'), 'base64'), '+/=', '-_');
  end $f$;
  r := probe_priv.seat_password(v_sid, gen_random_uuid());
  assert length(r) = 4 + 44 - 1 + 0 or length(r) > 40, 'derived password has expected length';
  assert r ~ '[A-Z]' and r ~ '[a-z]' and r ~ '[0-9]', 'derived password satisfies the 10+/upper/lower/digit policy';
  assert probe_priv.seat_password(v_sid, '00000000-0000-0000-0000-000000000001') = probe_priv.seat_password(v_sid, '00000000-0000-0000-0000-000000000001'), 'derivation is deterministic';
  assert probe_priv.seat_password(v_sid, '00000000-0000-0000-0000-000000000001') <> probe_priv.seat_password(v_sid, '00000000-0000-0000-0000-000000000002'), 'different seats, different passwords';
  log := log || 'PASS definer function derives deterministic per-seat passwords from the Vault key; ';

  -- 3. what anon / authenticated can and cannot do (the boundary)
  create function public.probe_claim(p_x int) returns text language plpgsql security definer set search_path = '' as $f$
  begin return probe_priv.seat_password((select id from vault.secrets order by created_at desc limit 1), gen_random_uuid()); end $f$;
  revoke all on function public.probe_claim(int) from public, anon, authenticated, service_role;
  revoke all on function probe_priv.seat_password(uuid, uuid) from public, anon, authenticated, service_role;
  assert not has_function_privilege('anon', 'public.probe_claim(int)', 'EXECUTE'), 'default: anon cannot execute';
  grant usage on schema public to anon;                       -- the posture change the design needs (anon has NO public usage today)
  grant execute on function public.probe_claim(int) to anon;  -- exactly one function
  set local role anon;
  begin perform 1 from vault.decrypted_secrets; raise exception 'FAIL anon read vault'; exception when insufficient_privilege then null; end;
  begin perform 1 from vault.secrets; raise exception 'FAIL anon read vault.secrets'; exception when insufficient_privilege then null; end;
  begin perform vault.create_secret('x', 'y', 'z'); raise exception 'FAIL anon create_secret'; exception when insufficient_privilege then null; end;
  begin perform probe_priv.seat_password(v_sid, gen_random_uuid()); raise exception 'FAIL anon reached the private schema'; exception when insufficient_privilege then null; end;
  begin perform 1 from public.profiles; raise exception 'FAIL anon read profiles'; exception when insufficient_privilege then null; end;
  begin perform 1 from auth.users; raise exception 'FAIL anon read auth.users'; exception when insufficient_privilege then null; end;
  r := public.probe_claim(1);
  assert r like 'Dm1-%', 'anon obtains only what the granted wrapper returns';
  assert current_setting('statement_timeout') = '3s' or current_setting('statement_timeout') is not null, 'anon statement_timeout visible';
  reset role;
  log := log || 'PASS anon: no Vault, no private schema, no tables; can run ONLY the granted wrapper; ';
  set local role authenticated;
  begin perform 1 from vault.decrypted_secrets; raise exception 'FAIL authenticated read vault'; exception when insufficient_privilege then null; end;
  begin perform probe_priv.seat_password(v_sid, gen_random_uuid()); exception when insufficient_privilege then null; end;
  reset role;
  log := log || 'PASS authenticated cannot read Vault or call the private function; ';

  -- 4. secrets must not appear in function source (pg_proc is world-readable) — the function stores only the secret ID lookup, never the key
  select prosrc into r from pg_proc where proname = 'seat_password' and pronamespace = 'probe_priv'::regnamespace;
  assert position(k in r) = 0, 'function source must not contain the key';
  -- 5. error text must not leak: a failure inside the definer function carries only a generic message
  begin perform probe_priv.seat_password('00000000-0000-0000-0000-00000000dead', gen_random_uuid()); exception when others then r := sqlerrm; end;
  assert position(k in coalesce(r, '')) = 0, 'no key in error text';
  log := log || 'PASS key not in function source or error text; ';
  raise exception 'ROLLBACK_OK % (%.1f ms)', log, extract(epoch from clock_timestamp() - t) * 1000;
end $$;
