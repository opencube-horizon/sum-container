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

case "${1:-}" in
    clean-cache)
        echo "Cleaning SUM cache in /data/sum ..."
        rm -rf /data/sum/baseline
        rm -f  /data/sum/sum.pdb /data/sum/sum.pdb-wal /data/sum/sum.pdb-shm
        rm -f  /data/sum/sum_remote.pdb
        # Remove version-numbered directories (e.g. 12_5_0_20)
        find /data/sum -maxdepth 1 -type d -regex '.*/[0-9]+_[0-9]+_[0-9]+_[0-9]+' -exec rm -rf {} +
        echo "Done. Restart the container to launch SUM with a clean state."
        exit 0
        ;;
    "")
        exec /opt/sum/bin/x64/sum_bin_x64
        ;;
    *)
        echo "Unknown command: $1" >&2
        echo "Usage: <container> [clean-cache]" >&2
        exit 1
        ;;
esac
