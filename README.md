# Oduflow Stacks

Ready-to-apply [Oduflow](https://oduflow.dev) Declarative Stacks. Each folder is one stack: a
`oduflow.yaml` manifest plus a README. Clone the repository on your Oduflow server and apply the one
you want:

```bash
git clone https://github.com/oduflow/oduflow-stacks.git
cd oduflow-stacks/<stack>
oduflow stack plan oduflow.yaml --team 1
oduflow stack apply oduflow.yaml --team 1
```

| Stack | What you get |
|---|---|
| [mailpit](mailpit/) | A Mailpit test inbox and an Odoo playground whose outgoing mail goes to it |

Playground environments run this repository itself: `addons/` holds small helper modules the stacks
install (Odoo settings and sample data for each playground).

Stacks never delete anything: removing a resource from a manifest leaves it running. See
[Declarative Stacks](https://docs.oduflow.dev/stacks/) for the format and the apply rules.
