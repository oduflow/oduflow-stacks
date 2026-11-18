# Multica Docker Runtime (Machine)

Both `multica/oduflow.yaml` and `multica-odoo-production/oduflow.yaml` include
`multica-machine` and its private `multica-machine-home` volume. They share this
Dockerfile. Do not create a second Stack for the Machine.

The Machine is an **outbound task executor**, not another Web/API server. It
connects to your Multica server and runs coding tools. It needs no additional
database. Building the image does not log in, register a Machine, or change an
existing host daemon.

## Image contents

- Multica CLI 0.11.0, downloaded from the official release with SHA-256 checks.
- Amp 0.0.1795017641-g2e763e and Codex CLI 0.170.0.
- Claude Code is downloaded from npm on first start, not included in image layers.
- Node 24, Python 3 with venv, Git/SSH, curl, jq and ripgrep.
- Non-root `node` user (UID/GID 1000), `tini`, foreground daemon, concurrency 1.
- Automatic daemon updates and reloads disabled; update by rebuilding the image.

The published image includes Linux arm64 and amd64 variants. The Node tag and Debian repositories
are mutable, so the build is version-pinned but not fully hermetic. Only the
Dockerfile, entrypoint and `.dockerignore` enter the build context. No credentials are baked in.

## Run the prebuilt image (recommended)

Both Stack variants already reference the public Docker Hub image
[`oduist/multica-runtime:0.11.0-2`](https://hub.docker.com/r/oduist/multica-runtime).
Oduflow pulls it during `stack apply`; Docker selects Linux arm64 or amd64 for
the host automatically. You do not need a build environment, image-registry
configuration or a local image build for this path.

Follow the [shared Stack preparation](../README.md#prepare-the-host): configure
your domains, email allowlist, team secrets and WebSocket route. Then, from the
chosen Stack directory:

```sh
oduflow stack validate oduflow.yaml
oduflow stack plan oduflow.yaml --team 1
oduflow stack apply oduflow.yaml --team 1
```

This provisions the services; it does not authorize the Machine or its coding
tools. Complete [authentication and verification](#authenticate-and-verify)
before assigning tasks. Existing installations must review the plan first;
do not replace their domain edits or apply a stale manifest.

## Claude Code on first start

The entrypoint installs `@anthropic-ai/claude-code` directly from npm when
`claude` is not on PATH. It runs as `node`, using `NPM_CONFIG_PREFIX` at
`/home/node/.npm-global`; that directory is on PATH for the daemon and its child
processes. The existing home volume preserves the installation across container
recreation. Restarts reuse it without downloading or updating Claude again.

First start needs network access to npm and downloads the current npm release;
Claude's version is therefore not pinned by the image tag. If installation fails,
the entrypoint logs a warning and still starts Multica so Amp/Codex remain usable.
A later restart retries if `claude` is still missing. Check `claude --version`
before selecting the Claude provider, then run `claude auth login` in an
interactive container session as `node`. Installation does not authenticate it.
No ACP adapter is installed: this Machine runs Claude through Multica's CLI integration.

The published image does not redistribute Claude; the operator downloads it at
runtime, following the packaging approach used by Oduflow's coder image. Using
Claude remains subject to Anthropic's applicable terms. Keep the home volume
private; it contains both executable code and credentials.

## Build a custom image locally (optional)

From the repository root:

```sh
docker build --progress=plain -t multica-runtime:0.11.0-2 multica/runtime
```

**A local tag alone is not sufficient for Oduflow service creation.** Oduflow
pulls ordinary image references even when a matching image exists locally. Choose
one of these delivery paths before applying the Stack:

1. Publish to a registry you control, then replace
   `oduist/multica-runtime:0.11.0-2` in the chosen manifest with your custom
   image (prefer an immutable tag or digest). Authenticate Docker/Oduflow for a
   private registry. Publishing requires your approval and registry permissions.
2. Use Oduflow's native build workflow below and replace the image reference with
   the **exact staging tag returned by that build**. Do not manufacture a staging
   tag by retagging an unrelated local image.

The default published image avoids both of these custom-build steps.

## Build from a Dockerfile through Oduflow

Oduflow 1.92.0 provides `start_image_build`, `get_image_build`,
`publish_image_build` and `cancel_image_build`. The Stack schema accepts `image`,
not Compose-style `build:`; Stack apply does not build the Dockerfile.

Native builds require:

- A configured `[team.X.image_registry]` section, even for a staging-only build.
- An Oduflow **development environment with a managed Git checkout** containing
  this repository and the committed Dockerfile. A production target alone is
  insufficient; live-mounted `local_path` environments are rejected.
- The desired commit delivered to that checkout. Builds use `git archive HEAD`,
  not uncommitted local changes. No registry push occurs just by starting a build.

For an existing build environment named `catalog-build`, the CLI equivalents of
the MCP calls are:

```sh
oduflow call start_image_build '{"env_name":"catalog-build","context":"multica/runtime","dockerfile":"Dockerfile"}'
# Substitute the returned build_id, then check until status is succeeded:
oduflow call get_image_build '{"env_name":"catalog-build","build_id":"BUILD_ID"}'
```

`context` is relative to the repository root; `dockerfile` is relative to that
context. Optional `target` and `build_args` are supported; never put credentials
in build arguments. The Dockerfile also detects architecture via `dpkg` when
the Docker SDK builder does not supply BuildKit's `TARGETARCH` argument.

Use the reported `oduflow-build/team-<id>:<build-id>` staging image in the Stack
on the **same host and team**. Oduflow resolves this special reference locally
instead of pulling it. Staging images are temporary: retention preserves tags
used by containers, but unused tags can be pruned. For durable disaster recovery
or moving hosts, explicitly publish the verified build and use its registry
reference. Publication pushes the exact succeeded image, without rebuilding:

```sh
oduflow call publish_image_build '{"env_name":"catalog-build","build_id":"BUILD_ID","repository":"multica-runtime","tags":"0.11.0-2"}'
```

See [Oduflow image-build tools](https://docs.oduflow.dev/mcp-tools/#container-image-builds).

## Apply safely

Follow the [shared Stack preparation](../README.md#prepare-the-host), select
the correct team and retain the published Machine image unless using a custom build.
Preserve existing domain edits, secrets, Stack name and resource ownership.
Review the plan: when adding only a Machine to a synchronized installation,
expect only the new Machine volume and service. Stop if unrelated API, Web,
database or Odoo changes appear. Do not apply a stale deployment manifest.

Oduflow currently requires `port` or `routes` for every service, including
outbound daemons. The manifest uses port **1** with a `.localhost` hostname.
Nothing listens there: it is not a health endpoint or a public Machine URL.
Do not expose it through DNS/tunnels. Check Machine availability in Multica,
not through this placeholder Traefik route.

## Authenticate and verify

Authentication is intentionally separate from building and Stack configuration.
A fresh volume has no server identity; a running container alone does not mean
the Machine is ready. Configure the **new volume's** CLI with `multica config set
server_url https://multica.example.com` and `multica config set app_url
https://multica.example.com`, substituting the intended server. Authenticate with
its own PAT: `multica login --token` without a value prompts interactively.
Use an interactive container session as UID 1000 with the
Machine home volume, not a token in the manifest, image, shell history or logs.
Do not copy the host's existing Multica identity. Coordinate provisioning with
the foreground daemon; do not run two daemons against the same home volume.

`multica setup self-host --server-url … --app-url …` performs browser login and
starts a daemon; it does not connect Web to API. Its browser callback requires
container/tunnel reachability and is not a substitute for headless provisioning.

Authorize Amp, Codex or the runtime-installed Claude and Git access separately
in that same private home. Other providers installed on the host are not copied.
Explicitly select this Machine/provider in Multica, run a small test
task, then verify task output and persistence of identity/workspaces after a
controlled restart. Build-time version/help checks do **not** prove login,
online registration, MCP access or successful task execution.

The named volume persists `/home/node`, including `.multica`, coding-tool
credentials and `workspaces`. Back it up as sensitive data, separately from the
server database and attachments. Do not delete it when rebuilding the image.
No host home directory, SSH agent or Docker socket is mounted; privileged mode
and host networking are not needed. Outbound networking remains available:
this container is not a complete security boundary for untrusted agent code.
