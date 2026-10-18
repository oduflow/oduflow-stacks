import os

from odoo import Command


def post_init_hook(env):
    _mailpit_server(env)
    _sample_quotation(env)


def _mailpit_server(env):
    """Outgoing mail goes to Mailpit: no encryption, no login."""
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


def _sample_quotation(env):
    """A customer and a quotation, so there is something to send right away."""
    admin = env.ref("base.user_admin")
    if "tour_enabled" in admin._fields:
        admin.tour_enabled = False  # no onboarding tooltips in a playground
    company = env.company
    company.write({
        "name": "Mailpit Playground",
        "email": "sales@playground.example",
        "external_report_layout_id": env.ref("web.external_layout_standard").id,
    })
    admin.partner_id.write({"email": "admin@playground.example"})
    customer = env["res.partner"].create({
        "name": "Northwind Traders",
        "email": "orders@northwind.example",
        "is_company": True,
    })
    chair = env["product.product"].create({"name": "Ergonomic Office Chair", "list_price": 289.0})
    desk = env["product.product"].create({"name": "Height-Adjustable Desk", "list_price": 549.0})
    env["sale.order"].create({
        "partner_id": customer.id,
        "user_id": admin.id,  # shows up under "My Quotations"
        "order_line": [
            Command.create({"product_id": chair.id, "product_uom_qty": 4}),
            Command.create({"product_id": desk.id, "product_uom_qty": 2}),
        ],
    })
