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
# The sut RPM drops its service file at /opt/sut/scripts/sut.service but never
# installs it into systemd paths.  Write a custom unit calling sut directly
# instead of using HPE's sutd wrapper script.
cat > /usr/lib/systemd/system/sut.service <<'UNIT'
[Unit]
Description=HPE Integrated Smart Update Tools (iSUT)
After=network.target amsd.service

[Service]
Type=simple
ExecStart=/opt/sut/bin/sut /svc
# Register iSUT provider values in iLO RIS so SUM can detect it.
ExecStartPost=/opt/sut/bin/sut -register
ExecStartPost=/opt/sut/bin/sut -set mode=AutoDeployReboot
ExecStop=/opt/sut/bin/sut /deregister
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
UNIT
mkdir -p /etc/init.d /etc/rc.d/rc3.d /etc/rc.d/rc5.d /etc/rc.d/rc6.d
systemctl enable sut.service

# Serial console on iLO Virtual Serial Port (ttyS0 on Gen10+)
systemctl enable serial-getty@ttyS0.service

# Boot target — no GUI
systemctl set-default multi-user.target

#----------------------------------------------------------------------
# System configuration
#----------------------------------------------------------------------

passwd -d root

# Autologin root on iLO Virtual Serial Port (ttyS0 on Gen10+)
mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
cat > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 115200 linux
EOF

echo "hpe-appliance" > /etc/hostname
