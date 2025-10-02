#!/bin/bash -l

set -euo pipefail

if [ "$#" -ne 1 ] ; then
    echo "Usage: $0 <SDR-REPO>"
    echo ""
    echo "Mirrors an HPE Linux SDR Repo to /assets/<SDR-REPO> using lftp, for consumption by SUM."
    echo "Example:"
    echo "  $0 spp-gen10/2025.07.00.00"
    exit 1
fi

exec lftp -c mirror -x 'vmw/$' --parallel=5 "https://downloads.linux.hpe.com/SDR/repo/$1" "/assets/$1"
