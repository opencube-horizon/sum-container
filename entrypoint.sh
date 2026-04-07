#!/bin/bash -l

set -euo pipefail

if [ ! -e /opt/sum/bin/sum.ini ] ; then
    echo "Writing /opt/sum/bin/sum.ini based on env variables"
    cat > /opt/sum/bin/sum.ini <<EOF
[CustomizedData]
oem_data_copied=false

[Engine]
mode=release
temp_dir=/data

[FTP]
port=disabled

[HEARTBEAT_SETTINGS]
masternode_hearbeat_time_interval=2
remotenode_hearbeat_time_interval=10
remotenode_heartbeat_elapsed_time=20

[HTTP]
certificate_duration=7
port=${PORT:-63001}
ssl_port=${SSL_PORT:-63002}
webserver_log=false

[Log]
column1=30
column2=100
file_name=engine.log
log_format=type3

[Web]
virtual_path=/opt/sum/bin/assets

[rpm]
nodeps=false
EOF
else
    echo "Ignoring any set environment variables because /opt/sum/bin/sum.ini has been provided"
fi

[ -n "${SUM_ROOT_PASSWORD:-}" ] && echo "root:${SUM_ROOT_PASSWORD}" | chpasswd
[ -n "${SUM_ROOT_PASSWORD_FILE:-}" ] &&  echo "root:$(<${SUM_ROOT_PASSWORD_FILE})" | chpasswd

if [ -z "${SUM_ROOT_PASSWORD:-}" ] && [ -z "${SUM_ROOT_PASSWORD_FILE:-}" ] ; then
    echo "WARNING: Neither SUM_ROOT_PASSWORD nor SUM_ROOT_PASSWORD_FILE is set." >&2
    echo "         The default root password will be used, which is insecure." >&2
fi

unset SUM_ROOT_PASSWORD SUM_ROOT_PASSWORD_FILE

mkdir -p /data/sum

/opt/sum/bin/x64/sum_bin_x64 || true

SUM_PID=$(pgrep -x sum_service_x64)

shutdown() {
    echo "SIGTERM received, shutting down SUM engine..."
    /opt/sum/bin/x64/sum_bin_x64 shutdownengine
    exit 0
}
trap shutdown SIGTERM SIGINT

if [ -n "$SUM_PID" ]; then
    while kill -0 "$SUM_PID" 2>/dev/null; do
        sleep 5 &
        wait $! || true
    done
else
    echo "ERROR: sum_service_x64 is not running" >&2
    exit 1
fi
