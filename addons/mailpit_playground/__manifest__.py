{
    "name": "Mailpit Playground",
    "summary": "Send all outgoing mail to a Mailpit service and add a quotation to try it with",
    "description": """
Used by the mailpit stack in https://github.com/oduflow/oduflow-stacks.

On install it creates an outgoing mail server for Mailpit, whose address comes
from the container environment (MAILPIT_SMTP_HOST, required; MAILPIT_SMTP_PORT,
default 1025), and a customer with a quotation ready to be sent by email.
""",
    "version": "1.0",
    "author": "Oduist",
    "website": "https://oduflow.dev",
    "license": "LGPL-3",
    "category": "Hidden/Tools",
    "depends": ["mail", "sale_management"],
    "post_init_hook": "post_init_hook",
    "installable": True,
}
