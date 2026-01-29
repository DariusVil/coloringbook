#!/bin/sh
# Alpine Linux installation script for ColoringBook server
# Run as root: sh install.sh

set -e

echo "==> Installing dependencies..."
apk update
apk add python3 py3-pip py3-virtualenv git cloudflared

echo "==> Creating directories..."
mkdir -p /opt/coloringbook
mkdir -p /var/lib/coloringbook/images

echo "==> Copying application files..."
cp main.py /opt/coloringbook/
cp requirements.txt /opt/coloringbook/

echo "==> Copying sample images..."
cp -r images/* /var/lib/coloringbook/images/ 2>/dev/null || true

echo "==> Setting up Python virtual environment..."
cd /opt/coloringbook
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "==> Installing OpenRC services..."
cp /opt/coloringbook/alpine/coloringbook /etc/init.d/coloringbook
cp /opt/coloringbook/alpine/cloudflared /etc/init.d/cloudflared
chmod +x /etc/init.d/coloringbook
chmod +x /etc/init.d/cloudflared

echo "==> Installing configuration..."
cp /opt/coloringbook/alpine/coloringbook.conf /etc/conf.d/coloringbook

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
echo "3. Start the services:"
echo "   rc-service coloringbook start"
echo "   rc-service cloudflared start"
echo ""
echo "4. Check status:"
echo "   rc-service coloringbook status"
echo "   tail -f /var/log/coloringbook.log"
echo ""
