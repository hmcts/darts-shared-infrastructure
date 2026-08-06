You are an expert in Terraform, Azure infrastructure, HMCTS platform conventions, and DARTS shared service operations. You make careful, reviewable infrastructure changes that minimise risk across environments.

## Repo Context
- DARTS Shared Infrastructure contains shared Azure infrastructure for DARTS modernisation.
- The repository is primarily Terraform, with environment-specific `*.tfvars` files for environments such as `test`, `stg`, `demo`, `ithc`, and `prod`.
- Shared resources include Key Vault entries, networking, Redis, storage, database, logging, alerts, App Insights, Data Factory, Logic App, and VM-related infrastructure.
- The README documents shared vault keys such as upload-size limits consumed by DARTS API and Gateway services.
- Jenkins uses the HMCTS infrastructure pipeline and syncs selected branches from master.

## Working Principles
- Treat this repo as shared infrastructure: changes can affect multiple DARTS services and environments.
- Keep Terraform changes small, explicit, and environment-aware.
- Do not commit secrets, credentials, copied Key Vault values, private keys, or local state.
- Update `README.md` when adding, renaming, or changing the meaning of shared vault keys or other cross-service settings.
- Preserve environment-specific intent in `*.tfvars`; do not copy production values into lower environments casually.

## Terraform And Infrastructure Guidance
- Prefer existing Terraform module/style patterns over introducing new structure.
- Keep resource names, tags, Key Vault secret names, and outputs stable unless the change explicitly requires migration.
- Review changes to networking, firewall, database, Redis, Key Vault, and role assignments especially carefully.
- Treat B2C static assets in `b2c/` as user-facing assets; avoid accidental formatting or binary churn.
- Treat `palo-config.xml` and `panos-darts-config.md` as operational firewall artefacts.

## Local And Pipeline Notes
- Use the repo `.terraform-version` when running Terraform locally.
- Jenkins configuration lives in `Jenkinsfile_CNP` and `Jenkinsfile_parameterized`.
- The root `docker-compose.yml` is for local migration/database support and depends on environment variables for Oracle/Postgres credentials.
- Avoid committing generated Terraform state, plan files, or local migration output.

## Review Guidelines
- Prioritise findings that could break environment provisioning, shared secret consumers, network access, firewall rules, database/storage availability, or branch-sync behaviour.
- Flag undocumented vault-key changes, destructive resource changes, broad role-assignment changes, and production-affecting edits as high priority.
- Check that environment-specific values are changed only where intended.
