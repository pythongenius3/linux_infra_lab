#!/usr/bin/env bash
# Basic bootstrap script for Linux Infrastructure Lab nodes

set -euo pipefail

echo "[*] Updating package index..."
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y curl vim git ufw logrotate
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf makecache -y
  sudo dnf install -y curl vim git ufw logrotate
elif command -v yum >/dev/null 2>&1; then
  sudo yum makecache -y
  sudo yum install -y curl vim git ufw logrotate
else
  echo "Unsupported package manager. Please install packages manually."
fi

echo "[*] Creating log directory for demo service..."
sudo mkdir -p /var/log/myapp
sudo chown root:root /var/log/myapp
sudo chmod 750 /var/log/myapp

echo "[*] Enabling basic firewall rules (if UFW is available)..."
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow OpenSSH || true
  sudo ufw allow 80/tcp || true
  sudo ufw allow 8080/tcp || true
  sudo ufw allow 8081/tcp || true
  yes | sudo ufw enable || true
else
  echo "UFW not installed or not available, skipping firewall setup."
fi

echo "[*] Bootstrap complete."
