#!/usr/bin/env bash

# ===================================================

#  PTERODACTYL WINGS INSTALLER - NEXT GEN ULTRA EDITION

#                     2025 Edition

# ===================================================

#  Original Creator: MahimOp

#  YouTube : https://www.youtube.com/@mahimxyz

#  Discord : https://discord.gg/zkDNdPpArS

# ===================================================

set -e

# Next-Gen Neon Color Theme

RESET="\e[0m"

BOLD="\e[1m"

DIM="\e[2m"

UNDERLINE="\e[4m"

CYAN="\e[96m"

BLUE="\e[94m"

PURPLE="\e[95m"

GREEN="\e[92m"

YELLOW="\e[93m"

RED="\e[91m"

WHITE="\e[97m"

NEON_GREEN="\e[38;5;82m"

NEON_PURPLE="\e[38;5;165m"

NEON_BLUE="\e[38;5;75m"

GLOW="\e[38;5;51m"

clear

# Epic Wings Header

echo -e "${NEON_BLUE}"

cat << "EOF"

 __      __.__                      ________  

/  \    /  \__| ____   ____   ____  \_____  \ 

\   \/\/   /  |/ __ \ /    \_/ __ \  /  ____/ 

 \        /|  \  ___/|   |  \  ___/ /       \ 

  \__/\  / |__|\___  >___|  /\___  >\_______ \

       \/          \/     \/     \/         \/

EOF

echo -e "${NEON_PURPLE}${BOLD}             NEXT GEN ULTRA EDITION - 2025${RESET}"

echo -e "${GLOW}            High-Performance • Secure • Automated${RESET}"

echo -e "${DIM}      Original Creator: ${BOLD}MahimOp${RESET} ${DIM}| YouTube: @mahimxyz${RESET}"

echo -e "${DIM}      Discord: https://discord.gg/zkDNdPpArS${RESET}"

echo -e "${NEON_BLUE}══════════════════════════════════════════════════════════${RESET}\n"

# Status Functions

progress() { echo -e "${NEON_GREEN}${BOLD}➤ $1${RESET}"; }

success() { echo -e "${GREEN}${BOLD}✓ $1${RESET}"; }

warning() { echo -e "${YELLOW}${BOLD}! $1${RESET}"; }

error() { echo -e "${RED}${BOLD}✘ $1${RESET}"; }

# Root Check

if [ "$EUID" -ne 0 ]; then

    error "This script must be run as root (use sudo)"

    exit 1

fi

progress "Installing latest stable Docker..."

curl -sSL https://get.docker.com/ | CHANNEL=stable bash >/dev/null 2>&1

systemctl enable --now docker >/dev/null 2>&1

success "Docker installed and running!"

progress "Optimizing system for container performance..."

if [ -f "/etc/default/grub" ]; then

    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' /etc/default/grub

    update-grub >/dev/null 2>&1

    success "GRUB updated (reboot recommended for full effect)"

else

    warning "GRUB file not found – skipping kernel tweak"

fi

progress "Detecting system architecture..."

ARCH=$(uname -m)

if [ "$ARCH" == "x86_64" ]; then

    WINGS_ARCH="amd64"

else

    WINGS_ARCH="arm64"

fi

success "Architecture: $WINGS_ARCH"

progress "Downloading latest Pterodactyl Wings..."

mkdir -p /etc/pterodactyl

curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$WINGS_ARCH" >/dev/null 2>&1

chmod u+x /usr/local/bin/wings

success "Wings binary installed!"

progress "Creating Wings systemd service..."

cat > /etc/systemd/system/wings.service << 'EOF'

[Unit]

Description=Pterodactyl Wings Daemon

After=docker.service

Requires=docker.service

[Service]

User=root

WorkingDirectory=/etc/pterodactyl

LimitNOFILE=4096

PIDFile=/var/run/wings/daemon.pid

ExecStart=/usr/local/bin/wings

Restart=on-failure

RestartSec=5

StartLimitInterval=180

StartLimitBurst=30

[Install]

WantedBy=multi-user.target

EOF

systemctl daemon-reload

systemctl enable wings >/dev/null 2>&1

success "Wings service configured and enabled!"

progress "Generating self-signed SSL certificate..."

mkdir -p /etc/certs/wings

openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \

    -subj "/CN=wings.local" \

    -keyout /etc/certs/wings/privkey.pem \

    -out /etc/certs/wings/fullchain.pem >/dev/null 2>&1

success "SSL certificate created (replace with trusted cert in production)"

progress "Creating 'wing' helper command..."

cat > /usr/local/bin/wing << 'EOF'

#!/bin/bash

echo -e "\033[1;33mWings Helper Command\033[0m"

echo -e "\033[1;36m• Start Wings:\033[0m          \033[1;32msudo systemctl start wings\033[0m"

echo -e "\033[1;36m• Status:\033[0m              \033[1;32msudo systemctl status wings\033[0m"

echo -e "\033[1;36m• Live Logs:\033[0m           \033[1;32msudo journalctl -u wings -f\033[0m"

echo -e "\033[1;36m• Restart:\033[0m             \033[1;32msudo systemctl restart wings\033[0m"

echo -e "\033[1;33mEnsure port 8080 → 443 is forwarded!\033[0m"

EOF

chmod +x /usr/local/bin/wing

success "Helper command 'wing' created!"

# Auto-configuration option

echo -e "\n${YELLOW}${BOLD}Auto-Configuration Option${RESET}"

read -p $'\e[93m\e[1mDo you want to auto-configure Wings now? (y/N): \e[0m' AUTO_CONFIG

if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then

    echo -e "\n${CYAN}${BOLD}Enter details from your Pterodactyl Panel → Nodes → Configuration${RESET}\n"

    read -p $'\e[96mNode UUID: \e[0m' UUID

    read -p $'\e[96mToken ID: \e[0m' TOKEN_ID

    read -p $'\e[96mToken: \e[0m' TOKEN

    read -p $'\e[96mPanel URL (e.g., https://panel.example.com): \e[0m' REMOTE

    progress "Writing Wings configuration..."

    cat > /etc/pterodactyl/config.yml << EOF

debug: false

uuid: ${UUID}

token_id: ${TOKEN_ID}

token: ${TOKEN}

api:

  host: 0.0.0.0

  port: 8080

  ssl:

    enabled: true

    cert: /etc/certs/wings/fullchain.pem

    key: /etc/certs/wings/privkey.pem

  upload_limit: 100

system:

  data: /var/lib/pterodactyl/volumes

  sftp:

    bind_port: 2022

allowed_mounts: []

remote: '${REMOTE}'

EOF

    success "Configuration saved!"

    progress "Starting Wings daemon..."

    systemctl start wings

    success "Wings is now running!"

    echo -e "\n${GREEN}${BOLD}Auto-configuration complete!${RESET}"

else

    echo -e "\n${YELLOW}Auto-configuration skipped.${RESET}"

    echo -e "Configure manually by editing: ${WHITE}/etc/pterodactyl/config.yml${RESET}"

    echo -e "Then start Wings with: ${WHITE}sudo systemctl start wings${RESET}"

fi

# Final Epic Screen

clear

echo -e "${NEON_BLUE}"

cat << "EOF"

   __      __.__                      ________  

  /  \    /  \__| ____   ____   ____  \_____  \ 

  \   \/\/   /  |/ __ \ /    \_/ __ \  /  ____/ 

   \        /|  \  ___/|   |  \  ___/ /       \ 

    \__/\  / |__|\___  >___|  /\___  >\_______ \

         \/          \/     \/     \/         \/

EOF

echo -e "${NEON_PURPLE}${BOLD}       ✨ WINGS INSTALLATION COMPLETE ✨${RESET}\n"

echo -e "${GLOW}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"

echo -e "${CYAN}${BOLD}   Pterodactyl Wings is ready for takeoff!${RESET}"

echo -e "${GLOW}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}\n"

echo -e "${YELLOW}${BOLD}Quick Commands:${RESET}"

echo -e "   ${NEON_GREEN}•${RESET} Helper:          ${BOLD}wing${RESET}"

echo -e "   ${NEON_GREEN}•${RESET} Status:          ${BOLD}sudo systemctl status wings${RESET}"

echo -e "   ${NEON_GREEN}•${RESET} Logs:            ${BOLD}sudo journalctl -u wings -f${RESET}"

echo -e "   ${NEON_GREEN}•${RESET} Restart:         ${BOLD}sudo systemctl restart wings${RESET}\n"

warning "For production: Replace self-signed cert with Let's Encrypt!"

echo -e "${DIM}Tip: Use certbot with standalone mode or reverse proxy.${RESET}\n"

echo -e "${NEON_GREEN}${BOLD}Original Credits: MahimOp${RESET}"

echo -e "${DIM}YouTube: https://www.youtube.com/@mahimxyz${RESET}"

echo -e "${DIM}Discord: https://discord.gg/zkDNdPpArS${RESET}\n"

echo -e "${GLOW}${BOLD}Your servers are now powered by next-gen Wings! 🦅🚀${RESET}"

echo -e "\n${YELLOW}Press Enter to exit...${RESET}"

read -r
