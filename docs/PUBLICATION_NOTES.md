# Publication decisions

Option A, mobile only: smallest update but omits the current Web/backend.
Option B, full-stack monorepo: recommended and used; preserves both clients and one schema history.
Option C, separate repositories: adds coordination/versioning cost across shared RPC contracts.
Option D, monorepo plus release automation: useful later, but requires CI secrets, signing and deployment policy approval.
Option E, selected public modules: lowers disclosure scope but does not reproduce the full application.

B includes complete current application source with public configuration examples. Exclusions are operator-bound assets, obsolete implementations, generated build output and private QA—not application features. No `.github` deployment automation is added. No project license is invented. Owner decisions remain: publication approval, license, old GitHub-only file removals, portable provisioning, fresh backend/runtime acceptance and signing custody for any future Android release.

The ZIP belongs outside the source repository. Uploading the ZIP as one file does not update the GitHub source tree. Use the separate reviewed upload guide.
