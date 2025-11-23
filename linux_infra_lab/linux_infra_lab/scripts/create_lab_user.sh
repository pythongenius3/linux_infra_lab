#!/usr/bin/env bash
# Creates a lab user and adds to sudo (and docker if present)

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: sudo bash create_lab_user.sh <username>"
  exit 1
fi

USERNAME="$1"

if id "$USERNAME" >/dev/null 2>&1; then
  echo "[*] User '$USERNAME' already exists."
else
  echo "[*] Creating user '$USERNAME'..."
  sudo useradd -m -s /bin/bash "$USERNAME"
  echo "[*] Set a password for '$USERNAME':"
  sudo passwd "$USERNAME"
fi

echo "[*] Adding '$USERNAME' to sudo group..."
if getent group sudo >/dev/null 2>&1; then
  sudo usermod -aG sudo "$USERNAME"
elif getent group wheel >/dev/null 2>&1; then
  sudo usermod -aG wheel "$USERNAME"
fi

if getent group docker >/dev/null 2>&1; then
  echo "[*] Adding '$USERNAME' to docker group..."
  sudo usermod -aG docker "$USERNAME"
else
  echo "[*] Docker group not found; skipping docker group membership."
fi

echo "[*] User '$USERNAME' is ready for SSH and sudo access (after SSH is configured)."
