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
port=${PORT:=63001}
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

[ -n "${SUM_ROOT_PASSWORD_FILE:-}" ] &&  echo "root:$(<${SUM_ROOT_PASSWORD_FILE})" | chpasswd
[ -n "${SUM_ROOT_PASSWORD:-}" ] && echo "root:${SUM_ROOT_PASSWORD}" | chpasswd

exec /opt/sum/bin/x64/sum_service_x64
