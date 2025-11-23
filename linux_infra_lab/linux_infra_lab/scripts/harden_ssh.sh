#!/usr/bin/env bash
# Simple SSH hardening and firewall rules

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: sudo bash harden_ssh.sh <allowed_username>"
  exit 1
fi

USERNAME="$1"
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d%H%M%S)"

if ! id "$USERNAME" >/dev/null 2>&1; then
  echo "User '$USERNAME' does not exist. Create it first."
  exit 1
fi

echo "[*] Backing up sshd_config to $BACKUP..."
sudo cp "$SSHD_CONFIG" "$BACKUP"

echo "[*] Applying basic SSH hardening..."
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"

if ! grep -q "^AllowUsers" "$SSHD_CONFIG"; then
  echo "AllowUsers $USERNAME" | sudo tee -a "$SSHD_CONFIG" >/dev/null
else
  sudo sed -i "s/^AllowUsers.*/AllowUsers $USERNAME/" "$SSHD_CONFIG"
fi

echo "[*] Restarting SSH..."
if systemctl list-unit-files | grep -q sshd.service; then
  sudo systemctl restart sshd
else
  sudo systemctl restart ssh
fi

echo "[*] Ensuring firewall allows SSH and HTTP..."
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow OpenSSH || true
  sudo ufw allow 80/tcp || true
  sudo ufw allow 8080/tcp || true
  sudo ufw allow 8081/tcp || true
fi

echo "[*] SSH hardening complete. Test new connections before closing your existing session."
