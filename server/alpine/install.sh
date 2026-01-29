#!/bin/sh
# Alpine Linux installation script for ColoringBook server
#
# Usage:
#   sh alpine/install.sh          # Full install
#   sh alpine/install.sh update   # Just update init scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

TUNNEL_ID="5a9824d6-2cec-4b5e-8e9f-7252972bc109"
TUNNEL_HOSTNAME="coloringbook.brerum.com"

setup_cloudflared_config() {
    mkdir -p /root/.cloudflared

    if [ ! -f "/root/.cloudflared/config.yml" ]; then
        echo "==> Creating cloudflared config..."
        cat > /root/.cloudflared/config.yml << EOF
tunnel: ${TUNNEL_ID}
credentials-file: /root/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${TUNNEL_HOSTNAME}
    service: http://localhost:8000
  - service: http_status:404
EOF
    fi
}

update_services() {
    echo "==> Updating OpenRC services..."
    cp "$SCRIPT_DIR/coloringbook" /etc/init.d/coloringbook
    cp "$SCRIPT_DIR/cloudflared" /etc/init.d/cloudflared
    chmod +x /etc/init.d/coloringbook
    chmod +x /etc/init.d/cloudflared

    setup_cloudflared_config

    echo "==> Restarting services..."
    rc-service coloringbook restart 2>/dev/null || rc-service coloringbook start
    rc-service cloudflared restart 2>/dev/null || rc-service cloudflared start

    echo ""
    echo "Services updated and restarted."
    rc-service coloringbook status
    rc-service cloudflared status
}

if [ "$1" = "update" ]; then
    update_services
    exit 0
fi

echo "==> Installing dependencies..."
apk update
apk add python3 py3-pip py3-virtualenv cloudflared

echo "==> Creating images directory..."
mkdir -p /var/lib/coloringbook/images

echo "==> Copying sample images..."
cp -r "$SERVER_DIR/images/"* /var/lib/coloringbook/images/ 2>/dev/null || true

echo "==> Setting up Python virtual environment..."
cd "$SERVER_DIR"
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "==> Installing OpenRC services..."
cp "$SCRIPT_DIR/coloringbook" /etc/init.d/coloringbook
cp "$SCRIPT_DIR/cloudflared" /etc/init.d/cloudflared
chmod +x /etc/init.d/coloringbook
chmod +x /etc/init.d/cloudflared

echo "==> Installing configuration..."
cp "$SCRIPT_DIR/coloringbook.conf" /etc/conf.d/coloringbook

setup_cloudflared_config

echo "==> Enabling services to start on boot..."
rc-update add coloringbook default
rc-update add cloudflared default

echo "==> Starting services..."
rc-service coloringbook start
rc-service cloudflared start

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Edit your OpenAI API key:"
echo "   vi /etc/conf.d/coloringbook"
echo ""
echo "Check status:"
echo "   rc-service coloringbook status"
echo "   rc-service cloudflared status"
echo ""
