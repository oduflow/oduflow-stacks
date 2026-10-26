ARG INBOX_ZERO_VERSION=2.30.0
FROM ghcr.io/elie222/inbox-zero:${INBOX_ZERO_VERSION}

LABEL org.opencontainers.image.title="Inbox Zero for Oduflow"
LABEL org.opencontainers.image.description="Inbox Zero web and scheduled jobs in one Oduflow service"
LABEL org.opencontainers.image.source="https://github.com/oduflow/oduflow-stacks/tree/main/inbox-zero"
LABEL org.opencontainers.image.licenses="AGPL-3.0-only WITH Inbox-Zero-additional-terms"

COPY runtime.sh /usr/local/bin/inbox-zero-runtime
RUN chmod 0755 /usr/local/bin/inbox-zero-runtime

CMD ["/bin/sh", "/usr/local/bin/inbox-zero-runtime"]
