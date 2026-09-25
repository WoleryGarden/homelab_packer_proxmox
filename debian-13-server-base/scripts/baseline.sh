#!/bin/bash

set -eux

echo "==> Installing baseline software"
# Updating list of repositories
apt-get update
# Install pre-requisite packages
DEBIAN_FRONTEND=noninteractive apt-get install -y git rsync jq parted gpg gnupg cloud-guest-utils libnl-genl-3-200 systemd-timesyncd glances rsyslog qemu-guest-agent cloud-init screen
# Get the version of Debian
source /etc/os-release
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/debian/$VERSION_ID/packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
dpkg -i packages-microsoft-prod.deb
# Delete the Microsoft repository GPG keys file
rm packages-microsoft-prod.deb
# Install PowerShell
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y powershell
# Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
