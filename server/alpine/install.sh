#!/bin/sh
# Alpine Linux installation script for ColoringBook server
# Run as root from /root/coloringbook/server directory
#
# Usage:
#   sh alpine/install.sh          # Full install
#   sh alpine/install.sh update   # Just update init scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

update_services() {
    echo "==> Updating OpenRC services..."
    cp "$SCRIPT_DIR/coloringbook" /etc/init.d/coloringbook
    cp "$SCRIPT_DIR/cloudflared" /etc/init.d/cloudflared
    chmod +x /etc/init.d/coloringbook
    chmod +x /etc/init.d/cloudflared

    echo "==> Restarting services..."
    rc-service coloringbook restart 2>/dev/null || rc-service coloringbook start
    rc-service cloudflared restart 2>/dev/null || rc-service cloudflared start

    echo ""
    echo "Services updated and restarted."
    rc-service coloringbook status
    rc-service cloudflared status
}

# If "update" argument passed, just update services
if [ "$1" = "update" ]; then
    update_services
    exit 0
fi

# Full installation
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

echo "==> Enabling services to start on boot..."
rc-update add coloringbook default
rc-update add cloudflared default

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Edit your OpenAI API key:"
echo "   vi /etc/conf.d/coloringbook"
echo ""
echo "2. Configure cloudflared (if not already done):"
echo "   cloudflared tunnel login"
echo "   cloudflared tunnel create coloringbook"
echo ""
echo "3. Create cloudflared config:"
echo "   vi /root/.cloudflared/config.yml"
echo ""
echo "4. Start the services:"
echo "   rc-service coloringbook start"
echo "   rc-service cloudflared start"
echo ""
echo "5. Check status:"
echo "   rc-service coloringbook status"
echo "   tail -f /var/log/coloringbook.log"
echo ""
