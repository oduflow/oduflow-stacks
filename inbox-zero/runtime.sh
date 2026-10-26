#!/bin/sh

set -u

RUNTIME_DIR=${INBOX_ZERO_RUNTIME_DIR:-/var/lib/inbox-zero-runtime}
SECRETS_FILE="${RUNTIME_DIR}/runtime.env"
INTERNAL_API_URL=${INTERNAL_API_URL:-http://$(hostname):3000}
export INTERNAL_API_URL
WEB_URL=${INTERNAL_API_URL}

mkdir -p "${RUNTIME_DIR}"

if [ ! -f "${SECRETS_FILE}" ]; then
    umask 077
    {
        printf 'AUTH_SECRET=%s\n' "$(openssl rand -hex 32)"
        printf 'BETTER_AUTH_SECRET=%s\n' "$(openssl rand -hex 32)"
        printf 'NEXTAUTH_SECRET=%s\n' "$(openssl rand -hex 32)"
        printf 'EMAIL_ENCRYPT_SECRET=%s\n' "$(openssl rand -hex 32)"
        printf 'EMAIL_ENCRYPT_SALT=%s\n' "$(openssl rand -hex 16)"
        printf 'INTERNAL_API_KEY=%s\n' "$(openssl rand -hex 32)"
        printf 'API_KEY_SALT=%s\n' "$(openssl rand -hex 32)"
        printf 'CRON_SECRET=%s\n' "$(openssl rand -hex 32)"
    } >"${SECRETS_FILE}"
fi

set -a
# shellcheck disable=SC1090
. "${SECRETS_FILE}"
set +a

web_pid=""
cron_pids=""

stop_children() {
    trap - TERM INT
    for pid in ${cron_pids}; do
        kill "${pid}" 2>/dev/null || true
    done
    if [ -n "${web_pid}" ]; then
        kill "${web_pid}" 2>/dev/null || true
    fi
    wait 2>/dev/null || true
}

trap 'stop_children; exit 143' TERM INT

request() {
    path=$1
    if ! wget -q -O /dev/null \
        --header="Authorization: Bearer ${CRON_SECRET}" \
        "${WEB_URL}${path}"; then
        printf '[cron] request failed: %s\n' "${path}" >&2
    fi
}

run_loop() {
    path=$1
    interval=$2
    initial_delay=${3:-0}
    [ "${initial_delay}" -eq 0 ] || sleep "${initial_delay}"
    while true; do
        request "${path}"
        sleep "${interval}"
    done
}

run_daily_maintenance() {
    sleep 300
    while true; do
        for job in reasoning-retention mobile-push-retention email-send-operation-retention draft-cleanup; do
            request "/api/cron/${job}"
        done
        sleep 86400
    done
}

printf '[runtime] starting Inbox Zero web process\n'
/app/docker/scripts/start.sh &
web_pid=$!

until wget -q -O /dev/null "${WEB_URL}/"; do
    if ! kill -0 "${web_pid}" 2>/dev/null; then
        wait "${web_pid}"
        exit $?
    fi
    sleep 5
done

printf '[runtime] web is ready; starting scheduled jobs\n'
run_loop /api/cron/scheduled-actions 900 & cron_pids="${cron_pids} $!"
run_loop /api/cron/automation-jobs 900 & cron_pids="${cron_pids} $!"
run_loop /api/follow-up-reminders 3600 & cron_pids="${cron_pids} $!"
run_loop /api/resend/digest/all 1800 & cron_pids="${cron_pids} $!"
run_loop /api/meeting-briefs 900 & cron_pids="${cron_pids} $!"
run_loop /api/watch/all 21600 & cron_pids="${cron_pids} $!"
run_daily_maintenance & cron_pids="${cron_pids} $!"
run_loop /api/resend/inbox-health/all 86400 300 & cron_pids="${cron_pids} $!"
run_loop /api/resend/summary/all 604800 300 & cron_pids="${cron_pids} $!"

wait "${web_pid}"
status=$?
printf '[runtime] web exited with status %s; stopping scheduled jobs\n' "${status}" >&2
stop_children
exit "${status}"
