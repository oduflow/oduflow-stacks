# Multica with Odoo production

Run the same Multica Web, API, PostgreSQL database and attachment volume as the [service-only variant](../multica/), alongside a separate Odoo 19 production named `multica-odoo`. Each application owns its own database and login. The manifest deploys both applications together.

1. Complete the [shared Multica setup](../multica/#prepare-the-host) using the manifest and `.env.example` in **this** directory.
2. Set `spec.production.domain` to a separate Odoo hostname outside the Multica cookie domain. Configure its DNS and TLS. The default addon checkout is this public catalog's `main` branch. Replace `repoUrl` and `branch` before creation if Odoo should run your own addons.
3. From this directory run the [apply and verification commands](../multica/#apply-and-verify). Also open the Odoo hostname and complete your usual Oduflow production onboarding.

When extending an existing Multica Stack, copy its local domain edits and `.env` values and select the same team. Review the plan before applying. Matching Web, API, database and attachment resources are reused. This manifest expects to create the named Odoo production. Bringing an independently managed production into the Stack requires Oduflow's explicit adoption workflow.
