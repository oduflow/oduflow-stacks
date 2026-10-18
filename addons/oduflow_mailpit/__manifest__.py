{
    "name": "Oduflow Mailpit",
    "summary": "Send the outgoing mail of a test database to a Mailpit service",
    "description": """
Creates an outgoing mail server for Mailpit when the module is installed.
The address comes from the container environment: MAILPIT_SMTP_HOST
(required) and MAILPIT_SMTP_PORT (default 1025). Used by the mailpit
playground stack in https://github.com/oduflow/oduflow-stacks.
""",
    "version": "1.0",
    "author": "Oduist",
    "website": "https://oduflow.dev",
    "license": "LGPL-3",
    "category": "Hidden/Tools",
    "depends": ["mail"],
    "post_init_hook": "post_init_hook",
    "installable": True,
}
