-- V15b: a seat's user_id may become NULL (the Auth user was deleted by the operator cleanup; the FK ON DELETE SET NULL issues that UPDATE),
-- but it may never be re-pointed to a DIFFERENT user. Replaces only the trigger function from V15; nothing else changes.
create or replace function private.demo_seat_guard() returns trigger language plpgsql set search_path = '' as $$
begin
  if old.user_id is not null and new.user_id is not null and new.user_id is distinct from old.user_id then
    raise exception 'seat user is immutable' using errcode = 'PT409'; end if;
  if old.state = new.state then return new; end if;
  if not ((old.state = 'provisioning' and new.state in ('available', 'disabled', 'expired'))
       or (old.state = 'available' and new.state in ('claimed', 'disabled', 'expired'))
       or (old.state = 'claimed' and new.state in ('active', 'disabled', 'expired'))
       or (old.state = 'active' and new.state in ('disabled', 'expired'))
       or (old.state = 'disabled' and new.state = 'available' and new.generation > old.generation and new.nonce_hash is null)) then
    raise exception 'illegal seat transition % -> %', old.state, new.state using errcode = 'PT409';
  end if;
  return new;
end $$;
