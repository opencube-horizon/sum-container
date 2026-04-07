#!/bin/bash
# KIWI config.sh — runs inside the image root after package installation.

set -euxo pipefail

# Source KIWI helper functions
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#----------------------------------------------------------------------
# Install sut (Smart Update Tools) — skipping scriptlets
#----------------------------------------------------------------------
# The sut RPM's %prein runs DetectILO which fails without real iLO
# hardware (exit 255).  Download via zypper, install via rpm --noscripts.
# KIWI removes repo config before config.sh, so re-add it here.
SPP_REPO="https://downloads.linux.hpe.com/SDR/repo/spp-gen10/suse/SLES16/x86_64/__SPP_BASELINE__/"
zypper addrepo --no-gpgcheck "$SPP_REPO" spp-gen10
zypper --non-interactive --gpg-auto-import-keys refresh spp-gen10
zypper --non-interactive install --download-only sut
rpm -ivh --noscripts "$(find /var/cache/zypp -name 'sut-*.rpm' -type f | head -1)"
zypper removerepo spp-gen10
zypper clean -a

#----------------------------------------------------------------------
# Services
#----------------------------------------------------------------------

# HPE Agentless Management Service
systemctl enable amsd.service

# HPE Integrated Smart Update Tools
# The service name varies by package version; try known names.
systemctl enable sut.service 2>/dev/null \
    || systemctl enable hpsut.service 2>/dev/null \
    || echo "WARNING: could not enable sut service — check unit name" >&2

# Serial console on iLO Virtual Serial Port (ttyS1 on Gen10+)
systemctl enable serial-getty@ttyS1.service

# Boot target — no GUI
systemctl set-default multi-user.target

#----------------------------------------------------------------------
# System configuration
#----------------------------------------------------------------------

passwd -l root

# Autologin root on iLO Virtual Serial Port (ttyS1 on Gen10+)
mkdir -p /etc/systemd/system/serial-getty@ttyS1.service.d
cat > /etc/systemd/system/serial-getty@ttyS1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 115200 linux
EOF

echo "hpe-appliance" > /etc/hostname
