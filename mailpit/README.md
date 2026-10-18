# Mailpit playground

Test every email Odoo sends without reaching a real mailbox.
[Mailpit](https://mailpit.axllent.org) acts as an SMTP server, accepts every message and shows it in
its own inbox, with a web interface and a REST API.

This stack creates:

- **Mailpit** (`axllent/mailpit:v1.31`) as a team service. Odoo reaches it on the team network as
  `oduflow-1-svc-mailpit:1025`. The web UI (port 8025) is published as `mailpit.<your-domain>` and
  asks for the login from `.env`.
- **A volume** `mailpit-data`, so captured mail survives restarts and image updates.
- **An Odoo environment** `mailpit-playground`: a fresh Odoo 20 database with Sales. The
  `mailpit_playground` module points its outgoing mail server at Mailpit and adds a customer with a
  quotation to send.

## Try it

You need a running Oduflow server. Run these commands on that server:

```bash
git clone https://github.com/oduflow/oduflow-stacks.git
cd oduflow-stacks/mailpit
cp .env.example .env          # then set your own user:password in .env
oduflow stack plan oduflow.yaml --team 1
oduflow stack apply oduflow.yaml --team 1
```

Then:

1. Open Mailpit at `mailpit.<your-domain>` (or the URL on the service card in the dashboard) and sign
   in with the login from `.env`.
2. In the dashboard, use **Connect As** on the `mailpit-playground` environment.
3. In Sales, open the quotation for Northwind Traders, click **Send**, and send it.
4. The email, with the PDF attached, appears in Mailpit, and no customer received anything.

## Good to know

- **Team.** The SMTP host is `oduflow-<team id>-svc-mailpit`. If you apply the stack with a team
  other than `--team 1`, change `MAILPIT_SMTP_HOST` in `oduflow.yaml` to match.
- **Odoo version.** Odoo 20 needs PostgreSQL 16 or newer on the Oduflow server. On older servers,
  set `odooImage: odoo:19.0`.
- **Name conflicts.** A service called `mailpit` or a volume called `mailpit-data` that already
  exists outside the stack is reported as a conflict, not taken over. Rename them in `oduflow.yaml`.
- **Links in emails.** Odoo builds links from `web.base.url`. Set it to the environment's address
  under Settings › Technical › System Parameters (developer mode) if you want links in test emails
  to open the playground.
- **API.** `GET https://mailpit.<your-domain>/api/v1/messages`, with the same login, lists the
  captured mail for tests and AI agents.

## Clean up

Stacks never delete resources. To remove the playground:

```bash
oduflow call delete_environment mailpit-playground
oduflow call delete_service '{"name":"mailpit","save_preset":false}'
oduflow call delete_volume mailpit-data
```

Docs: [Declarative Stacks](https://docs.oduflow.dev/stacks/) ·
[Auxiliary Services](https://docs.oduflow.dev/services/)
