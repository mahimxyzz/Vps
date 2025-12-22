#!/bin/bash
set -e

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃         BLUEPRINT INSTALLER - NEXT-GEN EDITION v4                  ┃
# ┃                Official Blueprint Framework • 2025                 ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# ────────────────────────────────────────────────────────────────────────
# Colors & Styling
# ────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

PANEL_DIR="/var/www/pterodactyl"

# ────────────────────────────────────────────────────────────────────────
# Utility Functions
# ────────────────────────────────────────────────────────────────────────
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}✗ Please run as root (sudo -i)${NC}"
        exit 1
    fi
}

header() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD} $1 ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

run() {
    echo -e "${YELLOW}⏳ $1...${NC}"
    shift
    if "$@"; then
        echo -e "${GREEN}✓ Done${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
        exit 1
    fi
}

pause() {
    read -rp "Press ENTER to continue..."
}

# ────────────────────────────────────────────────────────────────────────
# Welcome
# ────────────────────────────────────────────────────────────────────────
welcome() {
clear
cat << "EOF"
   ___  _          _   _   ___   ___   ___   ___
  / __|| |__   ___| |_| |_| __| / _ \ | _ )
 | (__ | '_ \ / _ \  _|  _|__ \/ (_) || _ \
  \___||_.__/ \___/\__|\__|___/ \___/ |___/
EOF
echo -e "${CYAN}${BOLD}Blueprint Framework • Installer (Next-Gen)${NC}\n"
sleep 1
}

# ────────────────────────────────────────────────────────────────────────
# Fresh Install
# ────────────────────────────────────────────────────────────────────────
fresh_install() {
    check_root
    header "FRESH INSTALLATION • BLUEPRINT"

    run "Updating system" apt update
    run "Installing base packages" apt install -y curl git unzip zip ca-certificates gnupg

    # Node.js 20.x
    if ! command -v node >/dev/null; then
        run "Adding NodeSource repository" bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -"
        run "Installing Node.js 20" apt install -y nodejs
    fi

    run "Installing Yarn" npm install -g yarn

    if [ ! -d "$PANEL_DIR" ]; then
        echo -e "${RED}✗ Pterodactyl panel not found at:${NC} $PANEL_DIR"
        exit 1
    fi

    cd "$PANEL_DIR"

    run "Installing panel dependencies" yarn install --production

    header "Downloading Blueprint"

    run "Downloading blueprint.sh" curl -fsSL \
https://raw.githubusercontent.com/BlueprintFramework/framework/main/blueprint.sh \
-o blueprint.sh

    chmod +x blueprint.sh

    header "Running Blueprint Installer"
    bash blueprint.sh -install

    ln -sf "$PANEL_DIR/blueprint.sh" /usr/local/bin/blueprint

    echo -e "\n${GREEN}✓ Blueprint installed successfully!${NC}"
}

# ────────────────────────────────────────────────────────────────────────
# Reinstall
# ────────────────────────────────────────────────────────────────────────
reinstall() {
    header "REINSTALL BLUEPRINT"
    cd "$PANEL_DIR"
    if command -v blueprint >/dev/null; then
        blueprint -rerun-install
    else
        bash blueprint.sh -rerun-install
    fi
}

# ────────────────────────────────────────────────────────────────────────
# Update
# ────────────────────────────────────────────────────────────────────────
update() {
    header "UPDATE BLUEPRINT"
    cd "$PANEL_DIR"
    if command -v blueprint >/dev/null; then
        blueprint -upgrade
    else
        fresh_install
    fi
}

# ────────────────────────────────────────────────────────────────────────
# Menu
# ────────────────────────────────────────────────────────────────────────
menu() {
    echo "1) Fresh Install"
    echo "2) Reinstall"
    echo "3) Update"
    echo "0) Exit"
    echo
    read -rp "Select an option: " choice
}

# ────────────────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────────────────
welcome

while true; do
    menu
    case "$choice" in
        1) fresh_install ;;
        2) reinstall ;;
        3) update ;;
        0) echo "Bye 👋"; exit 0 ;;
        *) echo -e "${MAGENTA}Invalid option${NC}" ;;
    esac
    pause
done
