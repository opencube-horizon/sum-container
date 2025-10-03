#!/bin/bash -l

set -euo pipefail

list_baseline_locations() {
    echo "Found the following baseline locations:"
    find /assets -name masterdependency.xml -print0 -or -name prerequisite_bp.xml -print0 | xargs -r0 dirname
}


if [ "$#" -ne 1 ] ; then
    echo "Usage: $0 <SDR-REPO>"
    echo ""
    echo "Mirrors an HPE Linux SDR Repo to /assets/<SDR-REPO> using lftp, for consumption by SUM."
    echo "Example:"
    echo "  $0 spp-gen10/2025.09.00.00"
    echo ""
    list_baseline_locations
    exit 1
fi

exec lftp -c mirror -x 'vmw/$' --parallel=5 "https://downloads.linux.hpe.com/SDR/repo/$1" "/assets/$1"
list_baseline_locations
