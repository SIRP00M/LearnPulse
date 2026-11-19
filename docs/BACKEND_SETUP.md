# Backend reproduction and safety

Use a stock isolated Supabase local stack, PostgreSQL 17, with auth/storage schemas, roles, pgcrypto in `extensions`, and Supabase Vault (`vault.secrets`, `vault.decrypted_secrets`, secret creation/update functions). Plain PostgreSQL is insufficient. Verify extensions before applying the chain.

Only the active 16 timestamp-ordered migrations are included. The older seven-migration implementation, rollback/teardown operators, remote linking files and database exports are excluded. V0 supersedes legacy history. Version labels have intentional gaps (V8/V10); filename timestamps, not labels, define order.

CRITICAL: `20261109181524_v0_foundation.sql` tests empty public tables and relevant Storage objects then drops/recreates public. Empty-table checks do not prove an existing schema is disposable. Review and use on a fresh isolated stack only. Never run db push/reset against an existing hosted project as an upload step.

The packaged config differs only by disabling `[db.seed]` and clearing `sql_paths`: the original pointed at missing seed.sql. Private classrooms, Auth records, passwords, Vault contents, per-session derivation keys and demo seeds are not included. Migrations contain secret-management code, not actual Vault values.

Teacher assignment is server controlled through confirmed-email invitations. Staff rights require explicit staff/supervisor records. The public demo claims an already provisioned seat; a fresh database contains no seats or presenters. Environment-bound provisioning/account-rotation tools are omitted rather than shipped with a live target. A portable provisioning tool is future work requiring separate review.

Selected SQL tests are retained for engineering reference. Some require seeded fixture roles or a harness; they are not an automatic fresh-install acceptance suite. Historical v0 privilege expectations are known stale after later schema expansions. Full migration replay, cross-user runtime isolation and hosted Auth/Storage tests were NOT TESTED during packaging. No live database was modified.

Current official configuration reference: https://supabase.com/docs/guides/local-development/managing-config . Keep privileged credentials server-side and outside source control. Pin CLI 2.81.3 for this config; review CLI v3 migration separately.
