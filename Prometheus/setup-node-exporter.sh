#!/bin/bash

set -e

VERSION="1.8.1"
ARCH="linux-amd64"
USER="node_exporter"
BIN="/usr/local/bin/node_exporter"
SERVICE="/etc/systemd/system/node_exporter.service"
TMP="/tmp/node_exporter-${VERSION}.${ARCH}.tar.gz"
URL="https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.${ARCH}.tar.gz"

echo "=========================================="
echo " Prometheus Node Exporter ${VERSION}"
echo "=========================================="

echo "[1/6] Creating system user..."

if ! id "${USER}" >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin "${USER}"
fi

echo "[2/6] Downloading Node Exporter..."

wget -q --show-progress -O "${TMP}" "${URL}"

if [ ! -s "${TMP}" ]; then
    echo "ERROR: Download failed."
    exit 1
fi

echo "[3/6] Installing Node Exporter..."

rm -rf "/tmp/node_exporter-${VERSION}.${ARCH}"

tar -xzf "${TMP}" -C /tmp

install -o root -g root -m 0755 \
    "/tmp/node_exporter-${VERSION}.${ARCH}/node_exporter" \
    "${BIN}"

echo "[4/6] Creating systemd service..."

cat > "${SERVICE}" <<EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${USER}
Group=${USER}
Type=simple
ExecStart=${BIN}

[Install]
WantedBy=multi-user.target
EOF

echo "[5/6] Starting Node Exporter..."

systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter

echo "[6/6] Checking service..."

if systemctl is-active --quiet node_exporter; then
    echo ""
    echo "=========================================="
    echo " Node Exporter installed successfully"
    echo " Version: ${VERSION}"
    echo " Port: 9100"
    echo "=========================================="
else
    echo ""
    echo "ERROR: Node Exporter failed to start."
    systemctl status node_exporter --no-pager
    exit 1
fi

rm -f "${TMP}"
rm -rf "/tmp/node_exporter-${VERSION}.${ARCH}"
