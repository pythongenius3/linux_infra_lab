#!/usr/bin/env bash
# Installs a simple demo systemd service that writes to /var/log/myapp/myapp_demo.log

set -euo pipefail

SERVICE_NAME="myapp_demo"
LOG_DIR="/var/log/myapp"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SCRIPT_FILE="/usr/local/bin/${SERVICE_NAME}.sh"
LOGROTATE_FILE="/etc/logrotate.d/${SERVICE_NAME}"

if [ ! -d "$LOG_DIR" ]; then
  echo "[*] Creating log directory at $LOG_DIR..."
  sudo mkdir -p "$LOG_DIR"
  sudo chown root:root "$LOG_DIR"
  sudo chmod 750 "$LOG_DIR"
fi

echo "[*] Installing demo script to $SCRIPT_FILE..."
sudo tee "$SCRIPT_FILE" >/dev/null << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/myapp/myapp_demo.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "==== myapp_demo started at $(date) on $(hostname) ====" >> "$LOG_FILE"

while true; do
  echo "$(date) - myapp_demo heartbeat on $(hostname)" >> "$LOG_FILE"
  sleep 60
done
EOF

sudo chmod +x "$SCRIPT_FILE"

echo "[*] Installing systemd service file to $SERVICE_FILE..."
sudo tee "$SERVICE_FILE" >/dev/null << EOF
[Unit]
Description=MyApp Demo Service
After=network.target

[Service]
Type=simple
ExecStart=$SCRIPT_FILE
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Installing logrotate configuration..."
sudo tee "$LOGROTATE_FILE" >/dev/null << 'EOF'
/var/log/myapp/myapp_demo.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0640 root root
    postrotate
        systemctl reload myapp_demo.service >/dev/null 2>&1 || true
    endscript
}
EOF

echo "[*] Reloading systemd daemon and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}.service"
sudo systemctl start "${SERVICE_NAME}.service"

echo "[*] Demo service installed and started. Check status with: systemctl status ${SERVICE_NAME}.service"
