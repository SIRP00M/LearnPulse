-- V1: take the three RLS helper functions out of the API-exposed schema.
-- Advisor 0029 flagged them as callable through /rest/v1/rpc. ALTER FUNCTION ... SET SCHEMA keeps the
-- function identity (OID), so the existing policies keep working with no recreation, and their
-- ownership, SECURITY DEFINER, search_path and EXECUTE grants (authenticated only) are unchanged.
-- `private` is not listed in the API's exposed schemas, so PostgREST cannot route to it.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated, service_role;
grant usage on schema private to authenticated;  -- required for RLS policy evaluation

alter function public.is_course_owner(uuid) set schema private;
alter function public.is_course_member(uuid) set schema private;
alter function public.can_view_profile(uuid) set schema private;

alter default privileges for role postgres in schema private revoke all on functions from public, anon, authenticated, service_role;
alter default privileges for role postgres in schema private revoke all on tables from public, anon, authenticated, service_role;

notify pgrst, 'reload schema';
