# Coloring Book API Server

Simple FastAPI backend for serving coloring images.

## Quick Start (Local Development)

```bash
cd server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

cloudflared tunnel run 5a9824d6-2cec-4b5e-8e9f-7252972bc109

## API Endpoints

- `GET /api/health` - Health check
- `GET /api/images` - List all images with metadata
- `GET /images/{filename}` - Serve image file
- `GET /docs` - Swagger UI documentation

## Adding Images

Place PNG, JPG, or PDF files in the images directory. The filename (without extension) becomes the image ID and title.

Example: `unicorn-rainbow.png` → Title: "Unicorn Rainbow"

### Image Storage Configuration

By default, images are served from `./images/` (relative to main.py). For production, set the `COLORINGBOOK_IMAGES_DIR` environment variable to use a persistent directory outside the git repo:

```bash
export COLORINGBOOK_IMAGES_DIR=/var/lib/coloringbook/images
```

This keeps user/AI-generated images separate from the code, so deploys won't overwrite them.

## Testing

```bash
curl http://localhost:8000/api/health
curl http://localhost:8000/api/images
```

---

## Linux Server Deployment Guide

This section covers setting up the server on a new Linux machine and exposing it to the internet without a static IP.

### 1. Initial Server Setup

#### Install Python 3.9+

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv git
```

**Fedora/RHEL:**
```bash
sudo dnf install python3 python3-pip git
```

**Arch Linux:**
```bash
sudo pacman -S python python-pip git
```

#### Clone and Setup the Project

```bash
# Create app directory
sudo mkdir -p /opt/coloringbook
sudo chown $USER:$USER /opt/coloringbook

# Clone or copy files
cd /opt/coloringbook
# If using git:
# git clone <your-repo-url> .
# Or copy files manually

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

#### Set Up Persistent Image Storage

Create a separate directory for images that persists across deploys:

```bash
# Create persistent data directory
sudo mkdir -p /var/lib/coloringbook/images
sudo chown www-data:www-data /var/lib/coloringbook/images

# Copy your coloring images
sudo cp /path/to/your/images/*.png /var/lib/coloringbook/images/
```

**Directory structure:**
```
/opt/coloringbook/           # App code (from git, replaceable)
    main.py
    requirements.txt
    images/                  # Sample images for dev only (in git)

/var/lib/coloringbook/       # Persistent data (NOT in git)
    images/                  # User + AI-generated images
```

### 2. Create a Systemd Service

Create a service file for automatic startup and management:

```bash
sudo nano /etc/systemd/system/coloringbook.service
```

Add the following content:

```ini
[Unit]
Description=Coloring Book API Server
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/coloringbook
Environment="PATH=/opt/coloringbook/venv/bin"
Environment="COLORINGBOOK_IMAGES_DIR=/var/lib/coloringbook/images"
ExecStart=/opt/coloringbook/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Set permissions and enable the service:

```bash
# Set ownership for app code
sudo chown -R www-data:www-data /opt/coloringbook

# Set ownership for persistent images
sudo chown -R www-data:www-data /var/lib/coloringbook

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable coloringbook
sudo systemctl start coloringbook

# Check status
sudo systemctl status coloringbook

# View logs
sudo journalctl -u coloringbook -f
```

### 3. Exposing the Service (No Static IP)

Since your machine doesn't have a static IP, here are several options to expose the service:

---

#### Option A: Cloudflare Tunnel (Recommended - Free)

Cloudflare Tunnel creates a secure outbound connection from your server to Cloudflare's network, requiring no open ports or static IP.

**Setup:**

1. Create a free Cloudflare account and add a domain (or use a free subdomain)

2. Install cloudflared:
```bash
# Download and install
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

3. Authenticate with Cloudflare:
```bash
cloudflared tunnel login
```

4. Create a tunnel:
```bash
cloudflared tunnel create coloringbook
```

5. Configure the tunnel - create `/etc/cloudflared/config.yml`:
```yaml
tunnel: 5a9824d6-2cec-4b5e-8e9f-7252972bc109
credentials-file: /root/.cloudflared/5a9824d6-2cec-4b5e-8e9f-7252972bc109.json

ingress:
  - hostname: coloringbook.brerum.com
    service: http://localhost:8000
  - service: http_status:404
```

6. Route DNS:
```bash
cloudflared tunnel route dns coloringbook coloringbook.brerum.com
```

7. Run as a service:
```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

**iOS App Configuration:** Use `https://coloringbook.yourdomain.com` as the server URL.

---

#### Option B: Tailscale (Best for Private/Family Use - Free)

Tailscale creates a private mesh VPN. All devices on your Tailscale network can access each other directly. Ideal for family use where only your devices need access.

**Setup on Linux Server:**

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start and authenticate
sudo tailscale up

# Note your Tailscale IP (usually 100.x.x.x)
tailscale ip -4
```

**Setup on iOS:**
1. Install Tailscale from App Store
2. Sign in with the same account
3. Both devices are now on the same private network

**iOS App Configuration:** Use `http://<tailscale-ip>:8000` as the server URL (e.g., `http://100.64.0.1:8000`)

**Benefits:**
- No port forwarding needed
- End-to-end encrypted
- Works across NAT and firewalls
- Free for personal use (up to 100 devices)

---

#### Option C: ngrok (Quick Testing - Free Tier Limited)

ngrok provides instant public URLs. Good for testing but the free tier has limitations (random URLs, connection limits).

**Setup:**

1. Install ngrok:
```bash
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
  sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
  sudo tee /etc/apt/sources.list.d/ngrok.list && \
  sudo apt update && sudo apt install ngrok
```

2. Sign up at https://ngrok.com and get your auth token

3. Configure ngrok:
```bash
ngrok config add-authtoken <YOUR_AUTH_TOKEN>
```

4. Start tunnel:
```bash
ngrok http 8000
```

5. Note the forwarding URL (e.g., `https://abc123.ngrok-free.app`)

**For persistent tunnels**, create a systemd service:

```bash
sudo nano /etc/systemd/system/ngrok.service
```

```ini
[Unit]
Description=ngrok tunnel
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ngrok http 8000 --log=stdout
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**Note:** Free ngrok URLs change on restart. Paid plans offer stable subdomains.

---

#### Option D: Dynamic DNS + Port Forwarding

If you can configure your router, use Dynamic DNS with port forwarding.

**Setup:**

1. Sign up for a free DDNS service:
   - [DuckDNS](https://www.duckdns.org/) (free)
   - [No-IP](https://www.noip.com/) (free tier)
   - [FreeDNS](https://freedns.afraid.org/) (free)

2. Install DDNS update client (example for DuckDNS):
```bash
# Create update script
mkdir -p ~/duckdns
echo "url=\"https://www.duckdns.org/update?domains=YOUR_DOMAIN&token=YOUR_TOKEN&ip=\"" > ~/duckdns/duck.sh
chmod 700 ~/duckdns/duck.sh

# Add to crontab (updates every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1") | crontab -
```

3. Configure port forwarding on your router:
   - Forward external port 8000 (or 80/443) to your server's internal IP on port 8000
   - The process varies by router - check your router's admin interface

4. (Optional) Add nginx as reverse proxy with SSL:
```bash
sudo apt install nginx certbot python3-certbot-nginx

# Configure nginx
sudo nano /etc/nginx/sites-available/coloringbook
```

```nginx
server {
    listen 80;
    server_name yourname.duckdns.org;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/coloringbook /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Get SSL certificate
sudo certbot --nginx -d yourname.duckdns.org
```

---

### Comparison Table

| Method | Cost | Setup Difficulty | Static URL | HTTPS | Best For |
|--------|------|------------------|------------|-------|----------|
| **Cloudflare Tunnel** | Free | Medium | ✅ Yes | ✅ Yes | Production use |
| **Tailscale** | Free | Easy | ✅ Yes* | ✅ Yes | Family/private use |
| **ngrok** | Free/Paid | Easy | ❌ Free / ✅ Paid | ✅ Yes | Quick testing |
| **DDNS + Port Forward** | Free | Hard | ✅ Yes | Optional | Full control |

*Tailscale IPs are stable but only accessible from your Tailscale network.

---

### Troubleshooting

**Service won't start:**
```bash
# Check logs
sudo journalctl -u coloringbook -n 50

# Test manually
cd /opt/coloringbook
source venv/bin/activate
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

**Permission denied:**
```bash
sudo chown -R www-data:www-data /opt/coloringbook
sudo chmod -R 755 /opt/coloringbook
```

**Port already in use:**
```bash
# Find what's using port 8000
sudo lsof -i :8000
# Kill if needed
sudo kill -9 <PID>
```

**Firewall blocking connections:**
```bash
# Ubuntu/Debian with ufw
sudo ufw allow 8000/tcp

# RHEL/Fedora with firewalld
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

**Test from iOS fails:**
- Ensure both devices are on the same network (for local testing)
- Check that the server URL in the app matches your setup
- Try accessing `http://<server-ip>:8000/api/health` from a browser first
