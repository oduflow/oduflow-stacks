import os


def post_init_hook(env):
    """Point outgoing mail at Mailpit (no encryption, no login)."""
    host = os.environ.get("MAILPIT_SMTP_HOST")
    if not host:
        return
    values = {
        "name": "Mailpit",
        "smtp_host": host,
        "smtp_port": int(os.environ.get("MAILPIT_SMTP_PORT") or 1025),
        "smtp_encryption": "none",
        "sequence": 1,
    }
    server = env["ir.mail_server"].search([("smtp_host", "=", host)], limit=1)
    if server:
        server.write(values)
    else:
        env["ir.mail_server"].create(values)
