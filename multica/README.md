# Multica

Run Multica v0.10.0 behind Oduflow's HTTPS router. The Web and API containers use a managed PostgreSQL database and a named volume for attachments. To run Odoo alongside Multica, use the [Odoo production variant](../multica-odoo-production/).

## Prepare the host

Use an Oduflow build with service-only Stacks and per-database cluster selection (introduced in [97fd51a1](https://github.com/oduflow/oduflow/commit/97fd51a1)). Enable Traefik TLS and production hosting. Both variants place the Multica database on the production PostgreSQL cluster, including the variant without Odoo.

Multica v0.10.0 requires PostgreSQL **17** with `pgcrypto` and `pg_trgm` available. The standard `postgres:17` image includes both. Verify the running cluster version before applying. The API runs its own migrations on startup. [Upstream database requirements](https://github.com/multica-ai/multica/blob/v0.10.0/SELF_HOSTING_ADVANCED.md#database-setup)

1. In the chosen manifest, replace every occurrence of `multica.example.com` with a domain dedicated to this Multica installation. Point its `app` and `api` DNS records at Traefik and configure TLS for both. The Web container must also be able to reach the HTTPS API address. Keep the common cookie domain limited to hosts you trust with Multica sessions.
2. Copy `.env.example` to `.env` in the chosen directory. Set the permitted signup addresses and the SMTP settings for verification emails. The sample uses authenticated SMTP on port 587 with STARTTLS.
3. In the target team's Oduflow Secrets, set the following values once and keep them when switching variants.

| Team secret | Value |
|---|---|
| `multica-jwt` | Session signing secret. Generate with `openssl rand -hex 32`. |
| `multica-vcs` | Git integration encryption key. Generate separately with `openssl rand -base64 32`. |
| `multica-smtp` | Password for the configured SMTP account. |

## Apply and verify

From the chosen directory, replace team `1` with your team ID as needed.

```sh
oduflow stack validate oduflow.yaml
oduflow stack plan oduflow.yaml --team 1
oduflow stack apply oduflow.yaml --team 1
oduflow stack status oduflow.yaml --team 1
```

Wait for `https://api.multica.example.com/healthz` on your actual API domain to report a healthy database and completed migrations. Open the Web domain, sign in with an allowed address, then upload and download an attachment. To run agent tasks, connect a Multica runtime following the [self-host guide](https://github.com/multica-ai/multica/blob/v0.10.0/SELF_HOSTING.md).

Back up the `multica-attachments` volume separately from PostgreSQL. The database participates in cluster-wide WAL-G backups when those are configured.

## Add Odoo later

Use the same team, Stack name, resource names, domains, secrets and SMTP settings in both variants. The only manifest difference is the Odoo production block. With Multica already in sync, the production variant's plan should add only Odoo. Applying the service-only manifest again leaves an existing Odoo production running.
