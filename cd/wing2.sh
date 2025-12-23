#!/bin/bash
set -e

# Bright colors + Bold for maximum impact
RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
BLUE='\033[0;94m'
PURPLE='\033[0;95m'
CYAN='\033[0;96m'
WHITE='\033[0;97m'
NC='\033[0m'
BOLD='\033[1m'

# Combined bold colors
B_RED="${RED}${BOLD}"
B_GREEN="${GREEN}${BOLD}"
B_YELLOW="${YELLOW}${BOLD}"
B_BLUE="${BLUE}${BOLD}"
B_PURPLE="${PURPLE}${BOLD}"
B_CYAN="${CYAN}${BOLD}"
B_WHITE="${WHITE}${BOLD}"

# Fancy borders & icons
TOP_BORDER="${B_BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
MID_BORDER="${B_BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
BOT_BORDER="${B_BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
DIVIDER="${B_BLUE}║${NC}                                                              ${B_BLUE}║${NC}"

# Fancy header function
print_header() {
    clear_line() { echo -e "${B_BLUE}║${NC}                                                              ${B_BLUE}║${NC}"; }
    echo -e "$TOP_BORDER"
    clear_line
    printf "${B_BLUE}║${NC}   ${B_PURPLE}%58s${NC}   ${B_BLUE}║${NC}\n" "$1"
    clear_line
    echo -e "$BOT_BORDER\n"
}

# Status messages with icons
print_status() {
    echo -e "${B_YELLOW}      ⏳ $1...${NC}"
}
print_success() {
    echo -e "${B_GREEN}      ✅ $1${NC}"
}
print_error() {
    echo -e "${B_RED}      ❌ $1${NC}"
}
print_info() {
    echo -e "${B_CYAN}      ℹ️ $1${NC}"
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

# Epic welcome banner
clear
echo -e "${B_BLUE}
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ${B_PURPLE}██████╗ ████████╗███████╗██████╗  █████╗  ██████╗████████╗██╗   ██╗██╗     ${B_BLUE}     ║
║     ${B_PURPLE}██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██║   ██║██║     ${B_BLUE}     ║
║     ${B_PURPLE}██████╔╝   ██║   █████╗  ██████╔╝███████║██║        ██║   ██║   ██║██║     ${B_BLUE}     ║
║     ${B_PURPLE}██╔═══╝    ██║   ██╔══╝  ██╔══██╗██╔══██║██║        ██║   ██║   ██║██║     ${B_BLUE}     ║
║     ${B_PURPLE}██║        ██║   ███████╗██║  ██║██║  ██║╚██████╗   ██║   ╚██████╔╝███████╗${B_BLUE}     ║
║     ${B_PURPLE}╚═╝        ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚══════╝${B_BLUE}     ║
║                                                              ║
║                  ${B_WHITE}W I N G S   S E T U P   S C R I P T${B_BLUE}                  ║
║                          ${B_CYAN}by MahimOp${B_BLUE}                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
${NC}"

print_info "Script created and maintained by MahimOp"
print_info "Discord: https://discord.gg/your-discord-invite-link"
echo

if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root or with sudo"
    exit 1
fi

print_header "STARTING INSTALLATION"

# 1. Docker
print_header "INSTALLING DOCKER"
print_status "Fetching and installing Docker"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash > /dev/null 2>&1
check_success "Docker installed successfully" "Docker installation failed"

print_status "Starting Docker service"
sudo systemctl enable --now docker > /dev/null 2>&1
check_success "Docker started and enabled" "Failed to start Docker"

# 2. GRUB
print_header "UPDATING SYSTEM"
if [ -f "/etc/default/grub" ]; then
    print_status "Applying GRUB tweak"
    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' /etc/default/grub
    sudo update-grub > /dev/null 2>&1
    check_success "GRUB updated" "GRUB update failed"
else
    print_info "No GRUB file found - skipping"
fi

# 3. Wings
print_header "INSTALLING PTERODACTYL WINGS"
print_status "Creating config directory"
sudo mkdir -p /etc/pterodactyl
check_success "Directory ready" "Directory creation failed"

print_status "Detecting architecture"
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH="arm64"
else
    print_error "Unsupported arch: $ARCH"
    exit 1
fi
print_success "Architecture: $ARCH"

print_status "Downloading latest Wings"
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH" > /dev/null 2>&1
check_success "Wings downloaded" "Download failed"

print_status "Making executable"
sudo chmod u+x /usr/local/bin/wings
check_success "Permissions applied" "Permission change failed"

# 4. Service
print_header "SETTING UP SYSTEMD SERVICE"
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
check_success "Service file created" "Service creation failed"

print_status "Reloading systemd"
sudo systemctl daemon-reload
check_success "Daemon reloaded" "Reload failed"

print_status "Enabling Wings"
sudo systemctl enable wings
check_success "Wings enabled on boot" "Enable failed"

# 5. SSL
print_header "GENERATING SSL CERTIFICATE"
print_status "Preparing cert directory"
sudo mkdir -p /etc/certs/wing
cd /etc/certs/wing

print_status "Creating self-signed certificate"
sudo openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
  -subj "/CN=localhost" -keyout privkey.pem -out fullchain.pem > /dev/null 2>&1
check_success "Certificate generated" "Cert generation failed"

# 6. wing helper
print_header "INSTALLING 'wing' HELPER"
print_status "Deploying helper command"
sudo tee /usr/local/bin/wing > /dev/null <<'EOF'
#!/bin/bash
echo -e "\033[0;95m\033[1m
╔════════════════════════════════════════════════╗
║              WINGS QUICK COMMANDS              ║
╚════════════════════════════════════════════════╝
\033[0m"
echo
echo -e "\033[0;96m\033[1mStart:     \033[0;92m\033[1msudo systemctl start wings\033[0m"
echo -e "\033[0;96m\033[1mStatus:    \033[0;92m\033[1msudo systemctl status wings\033[0m"
echo -e "\033[0;96m\033[1mLogs:      \033[0;92m\033[1mjournalctl -u wings -f\033[0m"
echo
echo -e "\033[0;93m\033[1m⚠️  Remember: Map port 8080 → 443 in node config!\033[0m"
echo
echo -e "\033[0;94m\033[1mSupport: https://discord.gg/your-discord-invite-link\033[0m"
echo
EOF
sudo chmod +x /usr/local/bin/wing
check_success "'wing' command ready" "Helper failed"

# Complete
print_header "INSTALLATION COMPLETE!"
echo -e "${B_GREEN}      🎉 Pterodactyl Wings is now fully installed and ready!${NC}\n"
echo -e "${B_WHITE}      Next Steps:${NC}"
echo -e " ${B_CYAN}      • Configure Wings (auto option below or manually)${NC}"
echo -e " ${B_CYAN}      • Start service: ${B_GREEN}sudo systemctl start wings${NC}"
echo -e " ${B_CYAN}      • Quick help: ${B_GREEN}wing${NC}\n"

# Auto-config
echo -e "${B_PURPLE}      🔧 Want to auto-configure Wings now?${NC}"
read -p "$(echo -e "${B_YELLOW}      Yes/No (y/N): ${NC}")" AUTO_CONFIG
if [[ "$AUTO_CONFIG" =~ ^[Yy]$ ]]; then
    print_header "AUTO CONFIGURATION"
    echo -e "${B_YELLOW}      Enter details from your Panel → Nodes → Configuration:${NC}\n"
    read -p "$(echo -e "${B_CYAN}      UUID: ${NC}")" UUID
    read -p "$(echo -e "${B_CYAN}      Token ID: ${NC}")" TOKEN_ID
    read -p "$(echo -e "${B_CYAN}      Token: ${NC}")" TOKEN
    read -p "$(echo -e "${B_CYAN}      Panel URL[](https://...): ${NC}")" REMOTE

    print_status "Writing config.yml"
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
    check_success "Config saved" "Config save failed"

    print_status "Launching Wings"
    sudo systemctl start wings
    check_success "Wings is running!" "Failed to start"

    echo -e "\n${B_GREEN}      ✅ Auto-configuration finished!${NC}"
    echo -e "${B_YELLOW}      Status:${NC} ${B_GREEN}systemctl status wings${NC}"
    echo -e "${B_YELLOW}      Logs:${NC} ${B_GREEN}journalctl -u wings -f${NC}\n"
else
    echo -e "\n${B_YELLOW}      ⚠️ Auto-config skipped${NC}"
    echo -e "${B_YELLOW}      Manual steps:${NC}"
    echo -e " ${B_GREEN}      1. Edit /etc/pterodactyl/config.yml${NC}"
    echo -e " ${B_GREEN}      2. sudo systemctl start wings${NC}\n"
fi

# Final epic footer
echo -e "${B_BLUE}
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║             ${B_WHITE}Thank you for using this setup script!${B_BLUE}             ║
║                     ${B_CYAN}Created by MahimOp${B_BLUE}                     ║
║          ${B_CYAN}Discord: https://discord.gg/your-discord-invite-link${B_BLUE}          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
${NC}"
