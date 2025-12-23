#!/bin/bash
set -e

# Colors (Bright variants for maximum visibility)
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
PURPLE='\033[0;95m'
CYAN='\033[0;96m'
WHITE='\033[0;97m'
NC='\033[0m'

# Backgrounds
BG_BLUE='\033[48;5;17m'
BG_PURPLE='\033[48;5;53m'

# Full bold for all colored text
BOLD_RED="${RED}${BOLD}"
BOLD_GREEN="${GREEN}${BOLD}"
BOLD_YELLOW="${YELLOW}${BOLD}"
BOLD_BLUE="${BLUE}${BOLD}"
BOLD_PURPLE="${PURPLE}${BOLD}"
BOLD_CYAN="${CYAN}${BOLD}"
BOLD_WHITE="${WHITE}${BOLD}"

# Header function - clean boxed design
print_header() {
    echo -e "\n${BG_BLUE}${BOLD_WHITE}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BG_PURPLE}${BOLD_WHITE}                      $1                      ${NC}"
    echo -e "${BG_BLUE}${BOLD_WHITE}══════════════════════════════════════════════════════════${NC}\n"
}

# Status messages - FULL BOLD + COLOR ONLY
print_status() {
    echo -e "${BOLD_YELLOW}⏳ $1...${NC}"
}
print_success() {
    echo -e "${BOLD_GREEN}✅ $1${NC}"
}
print_error() {
    echo -e "${BOLD_RED}❌ $1${NC}"
}
print_info() {
    echo -e "${BOLD_CYAN}ℹ️ $1${NC}"
}

check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
        return 0
    else
        print_error "$2"
        return 1
    fi
}

# Welcome screen
clear
echo -e "${BG_BLUE}${BOLD_WHITE}══════════════════════════════════════════════════════════${NC}"
echo -e "${BG_PURPLE}${BOLD_WHITE}             PTERODACTYL WINGS SETUP SCRIPT             ${NC}"
echo -e "${BG_PURPLE}${BOLD_WHITE}                       by MahimOp                       ${NC}"
echo -e "${BG_BLUE}${BOLD_WHITE}══════════════════════════════════════════════════════════${NC}\n"

print_info "Script created and maintained by MahimOp"
print_info "Discord: https://discord.gg/your-discord-invite-link"

if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

print_header "STARTING WINGS INSTALLATION"

# 1. Docker
print_header "INSTALLING DOCKER"
print_status "Installing Docker"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash > /dev/null 2>&1
check_success "Docker installed successfully" "Failed to install Docker"

print_status "Enabling and starting Docker"
sudo systemctl enable --now docker > /dev/null 2>&1
check_success "Docker service started" "Failed to start Docker"

# 2. GRUB
print_header "UPDATING SYSTEM CONFIG"
GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
    print_status "Updating GRUB"
    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' $GRUB_FILE
    sudo update-grub > /dev/null 2>&1
    check_success "GRUB updated" "Failed to update GRUB"
else
    print_info "GRUB file not found - skipping"
fi

# 3. Wings
print_header "INSTALLING WINGS"
print_status "Creating directory"
sudo mkdir -p /etc/pterodactyl
check_success "Directory created" "Failed to create directory"

print_status "Detecting architecture"
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
    print_success "AMD64 detected"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH="arm64"
    print_success "ARM64 detected"
else
    print_error "Unsupported architecture: $ARCH"
    exit 1
fi

print_status "Downloading Wings binary"
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH" > /dev/null 2>&1
check_success "Wings downloaded" "Download failed"

print_status "Setting permissions"
sudo chmod u+x /usr/local/bin/wings
check_success "Permissions set" "Failed to set permissions"

# 4. Service
print_header "CONFIGURING SERVICE"
print_status "Creating wings.service"
sudo tee /etc/systemd/system/wings.service > /dev/null <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
ExecStart=/usr/local/bin/wings
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
check_success "Service file created" "Failed to create service"

print_status "Reloading daemon"
sudo systemctl daemon-reload
check_success "Daemon reloaded" "Reload failed"

print_status "Enabling service"
sudo systemctl enable wings
check_success "Service enabled" "Enable failed"

# 5. SSL
print_header "GENERATING SSL CERT"
print_status "Creating cert directory"
sudo mkdir -p /etc/certs/wing
cd /etc/certs/wing

print_status "Generating self-signed cert"
sudo openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
  -subj "/CN=localhost" \
  -keyout privkey.pem -out fullchain.pem > /dev/null 2>&1
check_success "Certificate generated" "Cert generation failed"

# 6. wing helper
print_header "CREATING WING HELPER"
print_status "Installing helper"
sudo tee /usr/local/bin/wing > /dev/null <<'EOF'
#!/bin/bash
echo -e "\033[0;95m\033[1m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[0;95m\033[1m║         WINGS HELPER COMMAND             ║\033[0m"
echo -e "\033[0;95m\033[1m╚══════════════════════════════════════════╝\033[0m"
echo
echo -e "\033[0;96m\033[1mStart Wings:     \033[0;92m\033[1msudo systemctl start wings\033[0m"
echo -e "\033[0;96m\033[1mStatus:          \033[0;92m\033[1msudo systemctl status wings\033[0m"
echo -e "\033[0;96m\033[1mLive logs:       \033[0;92m\033[1mjournalctl -u wings -f\033[0m"
echo
echo -e "\033[0;93m\033[1m⚠️  Port 8080 → 443 must be mapped!\033[0m"
echo
echo -e "\033[0;94m\033[1mDiscord: https://discord.gg/your-discord-invite-link\033[0m"
echo
EOF
sudo chmod +x /usr/local/bin/wing
check_success "Helper created" "Helper creation failed"

# Complete
print_header "INSTALLATION COMPLETE"
echo -e "${BOLD_GREEN}🎉 Wings fully installed!${NC}\n"
echo -e "${BOLD_WHITE}Next Steps:${NC}"
echo -e " ${BOLD_CYAN}•${NC} Configure via auto-config below or manually"
echo -e " ${BOLD_CYAN}•${NC} Start: ${BOLD_GREEN}sudo systemctl start wings${NC}"
echo -e " ${BOLD_CYAN}•${NC} Help: ${BOLD_GREEN}wing${NC}\n"

# Auto-config
echo -e "${BOLD_PURPLE}🔧 AUTO-CONFIGURE WINGS?${NC}"
read -p "$(echo -e "${BOLD_YELLOW}Continue? (y/N): ${NC}")" AUTO_CONFIG
if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then
    print_header "AUTO CONFIGURATION"
    echo -e "${BOLD_YELLOW}Enter node details from Panel → Nodes → Configuration:${NC}\n"
    read -p "$(echo -e "${BOLD_CYAN}UUID: ${NC}")" UUID
    read -p "$(echo -e "${BOLD_CYAN}Token ID: ${NC}")" TOKEN_ID
    read -p "$(echo -e "${BOLD_CYAN}Token: ${NC}")" TOKEN
    read -p "$(echo -e "${BOLD_CYAN}Panel URL: ${NC}")" REMOTE

    print_status "Saving config"
    sudo tee /etc/pterodactyl/config.yml > /dev/null <<CFG
debug: false
uuid: ${UUID}
token_id: ${TOKEN_ID}
token: ${TOKEN}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/certs/wing/fullchain.pem
    key: /etc/certs/wing/privkey.pem
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
remote: '${REMOTE}'
CFG
    check_success "Config saved" "Save failed"

    print_status "Starting Wings"
    sudo systemctl start wings
    check_success "Wings started" "Start failed"

    echo -e "\n${BOLD_GREEN}✅ Auto-config complete!${NC}"
    echo -e "${BOLD_YELLOW}Status:${NC} ${BOLD_GREEN}systemctl status wings${NC}"
    echo -e "${BOLD_YELLOW}Logs:${NC} ${BOLD_GREEN}journalctl -u wings -f${NC}\n"
else
    echo -e "\n${BOLD_YELLOW}⚠️ Skipped auto-config${NC}"
    echo -e "${BOLD_YELLOW}Manual steps:${NC}"
    echo -e " ${BOLD_GREEN}1. Edit /etc/pterodactyl/config.yml${NC}"
    echo -e " ${BOLD_GREEN}2. sudo systemctl start wings${NC}\n"
fi

# Footer
echo -e "${BG_BLUE}${BOLD_WHITE}══════════════════════════════════════════════════════════${NC}"
echo -e "${BG_PURPLE}${BOLD_WHITE}                Thank you for using this script!                ${NC}"
echo -e "${BOLD_CYAN}                    Author: MahimOp                             ${NC}"
echo -e "${BOLD_CYAN}                    Discord: https://discord.gg/your-discord-invite-link                    ${NC}"
echo -e "${BG_BLUE}${BOLD_WHITE}══════════════════════════════════════════════════════════${NC}\n"
