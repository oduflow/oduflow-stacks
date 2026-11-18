# Multica

Run Multica v0.11.0 behind Oduflow's HTTPS router, with a Docker Runtime (Machine). The Web and API containers use a managed PostgreSQL database and a named volume for attachments. To run Odoo alongside Multica, use the [Odoo production variant](../multica-odoo-production/).

Both variants pull the prebuilt Docker Hub image [`oduist/multica-runtime:0.11.0-2`](https://hub.docker.com/r/oduist/multica-runtime) for Linux arm64 or amd64; no local build is required. Claude Code is downloaded on first start into the persistent home volume. They include the same Machine service and persistent home volume; there is no separate Machine Stack. Machine authentication and coding-tool authorization are separate provisioning steps. See the [Machine guide](runtime/README.md) for setup and optional custom builds.

## Prepare the host

Use an Oduflow build with service-only Stacks and per-database cluster selection (introduced in [97fd51a1](https://github.com/oduflow/oduflow/commit/97fd51a1)). Enable Traefik TLS and production hosting. Both variants place the Multica database on the production PostgreSQL cluster, including the variant without Odoo.

Multica v0.11.0 requires PostgreSQL **17** with `pgcrypto` and `pg_trgm` available. The standard `postgres:17` image includes both. Verify the running cluster version before applying. The API runs its own migrations on startup. [Upstream database requirements](https://github.com/multica-ai/multica/blob/v0.11.0/SELF_HOSTING_ADVANCED.md#database-setup)

1. In the chosen manifest and in `traefik-multica.yml`, replace `multica.example.com` with the hostname for Multica. Multica runs on this one origin: the Web container proxies the API over HTTP, so session cookies stay host-only. Point the hostname at Traefik. The manifest and the drop-in name the API container of team 1 (`oduflow-1-svc-multica-api`); change the `1` for another team.
2. Copy `traefik-multica.yml` into Oduflow's Traefik dynamic directory (`<config dir>/traefik-dynamic/`, for example `~/.oduflow/conf/traefik-dynamic/`). Next.js cannot forward WebSocket upgrades, so this route sends the browser (`/ws`) and daemon (`/api/daemon/ws`) WebSockets straight to the API. With `[routing] tls = true`, add `entryPoints: [websecure]` and `tls: {certResolver: letsencrypt}` to the router.
3. Copy `.env.example` to `.env` in the chosen directory and set the addresses allowed to sign up.
4. In the target team's Oduflow Secrets, set the following values once and keep them when switching variants.

| Team secret | Value |
|---|---|
| `multica-jwt` | Session signing secret. Generate with `openssl rand -hex 32`. |
| `multica-vcs` | Git integration encryption key. Generate separately with `openssl rand -base64 32`. |

## Apply and verify

From the chosen directory, replace team `1` with your team ID as needed.

```sh
oduflow stack validate oduflow.yaml
oduflow stack plan oduflow.yaml --team 1
oduflow stack apply oduflow.yaml --team 1
oduflow stack status oduflow.yaml --team 1
```

Wait for `https://multica.example.com/health` on your actual hostname to report a healthy database and completed migrations. Open the Web domain and enter an allowed address. Without SMTP, Multica prints the sign-in code to the API log: open the `multica-api` service logs in the Oduflow dashboard (or run `oduflow call get_service_logs '{"name": "multica-api"}'`) and copy the code from the `[DEV] Verification code for …` line. Then upload and download an attachment. To run agent tasks, complete the [Docker Machine authentication and verification](runtime/README.md#authenticate-and-verify). Alternatively, connect a host machine with `multica setup self-host --server-url https://multica.example.com --app-url https://multica.example.com` (see the [self-host guide](https://github.com/multica-ai/multica/blob/v0.11.0/SELF_HOSTING.md)).

Back up the `multica-attachments` volume separately from PostgreSQL. The database participates in cluster-wide WAL-G backups when those are configured.

## Email delivery

The Stack does not configure email. To send sign-in codes and invitations by email, add Multica's SMTP variables (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`) to the `multica-api` service, keeping the password in a team secret. See the [upstream email settings](https://github.com/multica-ai/multica/blob/v0.11.0/SELF_HOSTING_ADVANCED.md).

## Add Odoo later

Use the same team, Stack name, resource names, hostname and secrets in both variants. The only manifest difference is the Odoo production block. With Multica already in sync, the production variant's plan should add only Odoo. Applying the service-only manifest again leaves an existing Odoo production running.
