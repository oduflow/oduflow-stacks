#!/bin/sh
set -eu

# Download Claude directly for the user; never redistribute it in image layers.
# The npm prefix and CLI persist on the Machine's private home volume.
if ! command -v claude >/dev/null 2>&1; then
    printf '[multica-runtime] Installing Claude Code on first start\n' >&2
    if npm install --global --no-audit --no-fund @anthropic-ai/claude-code; then
        printf '[multica-runtime] Claude Code installed\n' >&2
    else
        printf '[multica-runtime] WARNING: Claude Code installation failed; Amp/Codex remain available. Restart to retry.\n' >&2
    fi
fi

exec /usr/local/bin/multica "$@"
