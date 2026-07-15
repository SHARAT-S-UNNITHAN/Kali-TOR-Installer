#!/bin/bash
# Enhanced TOR Installer for Kali Linux - FIXED VERSION
# Handles all issues with nyx and TOR Browser installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${BLUE}"
cat << "EOF"
    __  __     ______     ______
   / \/ \/\  /  __  \  /  _____/
  /      \ \/  /  \  \/  /____
 /  /\/\  \  /   /   \______  \
/  /    \  \/   /___/  _______/
\_/      \_/\_________/_________/
    TOR Installer for Kali Linux
    FIXED EDITION v2.1
EOF
echo -e "${NC}"

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then 
        echo -e "${RED}[-] Please don't run this script as root${NC}"
        echo -e "${YELLOW}[!] Run as normal user with sudo privileges${NC}"
        exit 1
    fi
}

# Function to check internet connection
check_internet() {
    echo -e "${BLUE}[*] Checking internet connection...${NC}"
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}[+] Internet connection OK${NC}"
    else
        echo -e "${RED}[-] No internet connection!${NC}"
        exit 1
    fi
}

# Function to install system dependencies
install_dependencies() {
    echo -e "${BLUE}[*] Updating package lists...${NC}"
    sudo apt update -qq 2>/dev/null || sudo apt update
    
    echo -e "${BLUE}[*] Installing TOR service and dependencies...${NC}"
    
    # Install core packages
    sudo apt install -y \
        tor \
        torsocks \
        obfs4proxy \
        python3-pip \
        python3-stem \
        python3-dev \
        curl \
        wget \
        net-tools \
        jq \
        xz-utils \
        build-essential \
        --no-install-recommends
    
    # Install nyx via pip with proper dependencies
    echo -e "${BLUE}[*] Installing nyx (TOR monitor)...${NC}"
    
    # First upgrade pip and install required dependencies
    sudo pip3 install --upgrade pip setuptools wheel
    
    # Install nyx with specific version that works
    if sudo pip3 install nyx==2.1.0 2>/dev/null; then
        echo -e "${GREEN}[+] nyx installed successfully via pip${NC}"
    else
        echo -e "${YELLOW}[!] nyx pip installation failed, trying alternative method...${NC}"
        # Try without version specification
        if sudo pip3 install nyx 2>/dev/null; then
            echo -e "${GREEN}[+] nyx installed successfully via pip${NC}"
        else
            echo -e "${YELLOW}[!] nyx not available, skipping...${NC}"
            echo -e "${YELLOW}[!] You can monitor TOR using: systemctl status tor${NC}"
        fi
    fi
}

# Function to get latest TOR Browser version
get_latest_version() {
    echo -e "${BLUE}[*] Fetching latest TOR Browser version...${NC}"
    
    # Try multiple sources for version
    LATEST_VERSION=$(curl -s https://www.torproject.org/download/ | grep -oP 'tor-browser-linux-x86_64-\K[0-9.]+(?=\.tar\.xz)' | head -1)
    
    if [ -z "$LATEST_VERSION" ]; then
        # Try alternative source
        LATEST_VERSION=$(curl -s https://dist.torproject.org/torbrowser/ | grep -oP 'href="\K[0-9.]+(?=/")' | sort -V | tail -1)
    fi
    
    if [ -z "$LATEST_VERSION" ]; then
        # Fallback to known working version
        LATEST_VERSION="13.5.1"
        echo -e "${YELLOW}[!] Could not fetch latest version, using fallback: $LATEST_VERSION${NC}"
    else
        echo -e "${GREEN}[+] Latest version: $LATEST_VERSION${NC}"
    fi
}

# Function to download and install TOR Browser (FIXED)
install_tor_browser() {
    echo -e "${BLUE}[*] Downloading TOR Browser...${NC}"
    cd /tmp
    
    # Try primary URL first
    TOR_URL="https://www.torproject.org/dist/torbrowser/${LATEST_VERSION}/tor-browser-linux-x86_64-${LATEST_VERSION}.tar.xz"
    
    echo -e "${YELLOW}[!] Downloading from: $TOR_URL${NC}"
    
    if ! wget -q --show-progress --timeout=30 "$TOR_URL" -O tor-browser.tar.xz 2>/dev/null; then
        echo -e "${YELLOW}[!] Primary download failed, trying mirror...${NC}"
        # Try dist mirror
        wget -q --show-progress "https://dist.torproject.org/torbrowser/${LATEST_VERSION}/tor-browser-linux-x86_64-${LATEST_VERSION}.tar.xz" -O tor-browser.tar.xz
    fi
    
    if [ ! -f tor-browser.tar.xz ] || [ ! -s tor-browser.tar.xz ]; then
        echo -e "${RED}[-] Download failed!${NC}"
        echo -e "${YELLOW}[!] Trying alternative version...${NC}"
        
        # Try specific known working versions
        for VERSION in "13.5.1" "13.0.15" "12.5.6"; do
            echo -e "${YELLOW}[!] Trying version $VERSION...${NC}"
            wget -q --show-progress "https://archive.torproject.org/tor-package-archive/torbrowser/${VERSION}/tor-browser-linux-x86_64-${VERSION}.tar.xz" -O tor-browser.tar.xz
            if [ -f tor-browser.tar.xz ] && [ -s tor-browser.tar.xz ]; then
                echo -e "${GREEN}[+] Download successful with version $VERSION${NC}"
                break
            fi
        done
        
        if [ ! -f tor-browser.tar.xz ] || [ ! -s tor-browser.tar.xz ]; then
            echo -e "${RED}[-] All download attempts failed!${NC}"
            echo -e "${YELLOW}[!] Please check your internet connection or download manually${NC}"
            echo -e "${YELLOW}[!] Manual download: https://www.torproject.org/download/${NC}"
            exit 1
        fi
    fi
    
    echo -e "${BLUE}[*] Installing TOR Browser...${NC}"
    
    # Remove old installation
    sudo rm -rf /opt/tor-browser
    
    # Extract the tarball - FIXED: handle the extraction properly
    echo -e "${BLUE}[*] Extracting TOR Browser...${NC}"
    tar -xf tor-browser.tar.xz
    
    # Find the extracted directory name
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "tor-browser*" | head -1)
    
    if [ -z "$EXTRACTED_DIR" ]; then
        echo -e "${RED}[-] Extraction failed! No tor-browser directory found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] Extracted to: $EXTRACTED_DIR${NC}"
    
    # Move to /opt
    sudo mv "$EXTRACTED_DIR" /opt/tor-browser
    sudo chown -R $USER:$USER /opt/tor-browser
    
    # Create symlink
    sudo ln -sf /opt/tor-browser/start-tor-browser /usr/local/bin/tor-browser 2>/dev/null || \
    sudo ln -sf /opt/tor-browser/Browser/start-tor-browser /usr/local/bin/tor-browser
    
    # Clean up
    rm -f /tmp/tor-browser.tar.xz
    
    echo -e "${GREEN}[+] TOR Browser installed successfully!${NC}"
}

# Function to create desktop entries
create_desktop_entries() {
    echo -e "${BLUE}[*] Creating desktop entries...${NC}"
    
    mkdir -p ~/.local/share/applications
    
    # Find correct icon path
    ICON_PATH=""
    if [ -f "/opt/tor-browser/Browser/browser/chrome/icons/default/default128.png" ]; then
        ICON_PATH="/opt/tor-browser/Browser/browser/chrome/icons/default/default128.png"
    elif [ -f "/opt/tor-browser/browser/chrome/icons/default/default128.png" ]; then
        ICON_PATH="/opt/tor-browser/browser/chrome/icons/default/default128.png"
    else
        ICON_PATH="firefox"
    fi
    
    # TOR Browser desktop entry
    cat > ~/.local/share/applications/tor-browser.desktop << DESKTOP
[Desktop Entry]
Name=TOR Browser
GenericName=Web Browser
Comment=Browse the Internet anonymously
Exec=/opt/tor-browser/start-tor-browser %U 2>/dev/null || /opt/tor-browser/Browser/start-tor-browser %U
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Network;WebBrowser;Security;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
DESKTOP
    
    # TOR Terminal desktop entry
    cat > ~/.local/share/applications/tor-terminal.desktop << DESKTOP
[Desktop Entry]
Name=TOR Terminal
Comment=Launch TOR-enabled terminal
Exec=gnome-terminal -- bash -c "echo '🔒 TOR Terminal Active'; echo 'IP: curl --socks5 localhost:9050 ifconfig.me'; export SOCKS5=localhost:9050; bash"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Network;System;
DESKTOP
}

# Function to create terminal helper scripts
create_terminal_scripts() {
    echo -e "${BLUE}[*] Creating TOR terminal helper scripts...${NC}"
    
    mkdir -p ~/.tor_scripts
    
    # TOR Control script (Main menu)
    cat > ~/.tor_scripts/tor-control.sh << 'CONTROL'
#!/bin/bash
# TOR Control Script

case "$1" in
    start)
        echo "[+] Starting TOR..."
        sudo systemctl start tor
        sleep 2
        if systemctl is-active --quiet tor; then
            echo "[+] TOR started successfully"
            echo "[+] TOR IP: $(curl --socks5 localhost:9050 ifconfig.me 2>/dev/null)"
        else
            echo "[-] TOR failed to start"
        fi
        ;;
    stop)
        echo "[+] Stopping TOR..."
        sudo systemctl stop tor
        echo "[+] TOR stopped"
        ;;
    status)
        echo "[+] TOR Status:"
        sudo systemctl status tor --no-pager
        ;;
    restart)
        echo "[+] Restarting TOR..."
        sudo systemctl restart tor
        echo "[+] TOR restarted"
        ;;
    ip)
        echo "[+] Your TOR IP:"
        curl --socks5 localhost:9050 ifconfig.me 2>/dev/null || echo "TOR not running"
        ;;
    check)
        echo "[+] Testing TOR connection..."
        if curl --socks5-hostname localhost:9050 https://check.torproject.org/ -s -o /dev/null -w "%{http_code}" | grep -q "200"; then
            echo "✅ TOR is working"
        else
            echo "❌ TOR is not working"
        fi
        ;;
    menu)
        ~/.tor_scripts/tor-menu.sh
        ;;
    *)
        echo "Usage: tor-control {start|stop|status|restart|ip|check|menu}"
        echo ""
        echo "  start   - Start TOR service"
        echo "  stop    - Stop TOR service"
        echo "  status  - Check TOR status"
        echo "  restart - Restart TOR"
        echo "  ip      - Show TOR IP"
        echo "  check   - Test TOR connection"
        echo "  menu    - Open interactive menu"
        ;;
esac
CONTROL
    chmod +x ~/.tor_scripts/tor-control.sh
    
    # Interactive menu
    cat > ~/.tor_scripts/tor-menu.sh << 'MENU'
#!/bin/bash
while true; do
    clear
    echo "╔═══════════════════════════════════════════════╗"
    echo "║     🌐 TOR CONTROL MENU 🌐                   ║"
    echo "╠═══════════════════════════════════════════════╣"
    echo "║  1. Start TOR Service                        ║"
    echo "║  2. Stop TOR Service                         ║"
    echo "║  3. Check TOR Status                         ║"
    echo "║  4. Restart TOR Service                      ║"
    echo "║  5. Show TOR IP                              ║"
    echo "║  6. Test TOR Connection                      ║"
    echo "║  7. Launch TOR Browser (GUI)                 ║"
    echo "║  8. Open TOR Terminal                        ║"
    echo "║  9. Edit TOR Configuration                   ║"
    echo "║  0. Exit                                     ║"
    echo "╚═══════════════════════════════════════════════╝"
    read -p "Choose an option: " choice
    
    case $choice in
        1) ~/.tor_scripts/tor-control.sh start; read -p "Press Enter..." ;;
        2) ~/.tor_scripts/tor-control.sh stop; read -p "Press Enter..." ;;
        3) ~/.tor_scripts/tor-control.sh status; read -p "Press Enter..." ;;
        4) ~/.tor_scripts/tor-control.sh restart; read -p "Press Enter..." ;;
        5) ~/.tor_scripts/tor-control.sh ip; read -p "Press Enter..." ;;
        6) ~/.tor_scripts/tor-control.sh check; read -p "Press Enter..." ;;
        7) 
            if command -v tor-browser &> /dev/null; then
                tor-browser &
            else
                echo "TOR Browser not found"
                sleep 2
            fi
            ;;
        8) 
            echo "🔒 TOR Terminal - All commands will use TOR"
            export SOCKS5=localhost:9050
            bash
            ;;
        9) 
            echo "Editing TOR configuration..."
            sudo nano /etc/tor/torrc
            echo "Restart TOR for changes to take effect"
            sleep 2
            ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option"; sleep 2 ;;
    esac
done
MENU
    chmod +x ~/.tor_scripts/tor-menu.sh
    
    # Create symlinks
    sudo ln -sf ~/.tor_scripts/tor-control.sh /usr/local/bin/tor
    sudo ln -sf ~/.tor_scripts/tor-menu.sh /usr/local/bin/tor-menu
    
    # Add aliases
    if ! grep -q "tor-control" ~/.bashrc; then
        cat >> ~/.bashrc << 'ALIASES'

# TOR Aliases
alias tor-start='sudo systemctl start tor'
alias tor-stop='sudo systemctl stop tor'
alias tor-status='sudo systemctl status tor'
alias tor-restart='sudo systemctl restart tor'
alias tor-ip='curl --socks5 localhost:9050 ifconfig.me'
alias tor-check='~/.tor_scripts/tor-control.sh check'
alias tor-menu='~/.tor_scripts/tor-menu.sh'
alias tshell='torsocks bash'
ALIASES
        echo -e "${GREEN}[+] Added TOR aliases to ~/.bashrc${NC}"
    fi
}

# Function to configure TOR
configure_tor() {
    echo -e "${BLUE}[*] Configuring TOR...${NC}"
    
    # Backup original config
    sudo cp /etc/tor/torrc /etc/tor/torrc.backup.$(date +%Y%m%d_%H%M%S)
    
    # Add common configurations if not already present
    if ! grep -q "SOCKSPort 9050" /etc/tor/torrc; then
        sudo bash -c 'cat >> /etc/tor/torrc << EOF

# Custom TOR Configurations
SOCKSPort 9050
ControlPort 9051
CookieAuthentication 1
CookieAuthFileGroupReadable 1
RunAsDaemon 1
EOF'
        echo -e "${GREEN}[+] TOR configured${NC}"
    else
        echo -e "${YELLOW}[!] TOR already configured${NC}"
    fi
}

# Function to enable and start TOR
enable_tor() {
    echo -e "${BLUE}[*] Enabling and starting TOR service...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable tor 2>/dev/null || echo -e "${YELLOW}[!] Could not enable TOR${NC}"
    sudo systemctl start tor 2>/dev/null || echo -e "${YELLOW}[!] Could not start TOR${NC}"
    sleep 3
    
    if sudo systemctl is-active --quiet tor; then
        echo -e "${GREEN}[+] TOR service is active!${NC}"
    else
        echo -e "${YELLOW}[!] TOR service not running. Check with: systemctl status tor${NC}"
    fi
}

# Function to test TOR
test_tor() {
    echo -e "${BLUE}[*] Testing TOR connection...${NC}"
    sleep 2
    
    if curl --socks5-hostname localhost:9050 https://check.torproject.org/ -s -o /dev/null -w "%{http_code}" | grep -q "200"; then
        echo -e "${GREEN}[+] TOR is working properly!${NC}"
        echo -e "${GREEN}[+] Your TOR IP:${NC}"
        curl --socks5-hostname localhost:9050 https://check.torproject.org/ -s 2>/dev/null | grep -oP '"IP":\s*"\K[^"]+' || echo "Unknown"
    else
        echo -e "${YELLOW}[!] TOR test failed. Starting TOR manually...${NC}"
        sudo systemctl start tor
        sleep 3
        if curl --socks5-hostname localhost:9050 https://check.torproject.org/ -s -o /dev/null -w "%{http_code}" | grep -q "200"; then
            echo -e "${GREEN}[+] TOR is now working!${NC}"
        else
            echo -e "${RED}[-] TOR still not working. Please check configuration.${NC}"
        fi
    fi
}

# Function to display usage
display_usage() {
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}      ✅ INSTALLATION COMPLETE! ✅${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo
    echo -e "${BLUE}📌 Quick Commands:${NC}"
    echo "  tor-menu       - Interactive TOR menu"
    echo "  tor {start|stop|status|restart|ip|check} - Control TOR"
    echo "  tor-browser    - Launch TOR Browser"
    echo "  tor-ip         - Show your TOR IP"
    echo "  tor-check      - Test TOR connection"
    echo "  tshell         - TOR-enabled shell"
    echo
    echo -e "${BLUE}📁 Scripts Location:${NC} ~/.tor_scripts/"
    echo -e "${BLUE}📁 TOR Browser Location:${NC} /opt/tor-browser/"
    echo
    echo -e "${GREEN}┌───────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│  🌐 Stay Anonymous, Stay Safe! 🛡️  │${NC}"
    echo -e "${GREEN}└───────────────────────────────────────┘${NC}"
    echo
    echo -e "${YELLOW}⚠️  First time setup:${NC}"
    echo "  1. Run 'tor-menu' to access all options"
    echo "  2. Or use 'tor start' to start the service"
    echo "  3. Launch TOR Browser with 'tor-browser'"
}

# Main installation function
main() {
    check_root
    check_internet
    
    echo -e "${YELLOW}[!] This will install TOR service and TOR Browser${NC}"
    echo -e "${YELLOW}[!] Estimated time: 2-5 minutes${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}[-] Installation cancelled${NC}"
        exit 0
    fi
    
    install_dependencies
    get_latest_version
    install_tor_browser
    create_desktop_entries
    create_terminal_scripts
    configure_tor
    enable_tor
    test_tor
    display_usage
    
    echo -e "${GREEN}[+] Installation complete!${NC}"
    echo -e "${YELLOW}[!] Run 'tor-menu' to get started${NC}"
}

# Run main function
main
