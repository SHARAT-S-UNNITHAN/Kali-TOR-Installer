#!/bin/bash
# Enhanced TOR Installer for Kali Linux
# Handles missing packages, provides both terminal and GUI TOR
# Version: 2.0 - Fully working with all dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    Enhanced Edition v2.0
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
        curl \
        wget \
        net-tools \
        jq \
        xz-utils \
        --no-install-recommends
    
    # Install nyx via pip instead of apt
    echo -e "${BLUE}[*] Installing nyx (TOR monitor)...${NC}"
    sudo pip3 install --upgrade nyx 2>/dev/null || {
        echo -e "${YELLOW}[!] nyx installation via pip failed, installing from apt...${NC}"
        sudo apt install -y nyx 2>/dev/null || {
            echo -e "${YELLOW}[!] nyx not available, skipping...${NC}"
        }
    }
}

# Function to get latest TOR Browser version
get_latest_version() {
    echo -e "${BLUE}[*] Fetching latest TOR Browser version...${NC}"
    LATEST_VERSION=$(curl -s https://www.torproject.org/download/ | grep -oP 'tor-browser-linux-x86_64-\K[0-9.]+(?=\.tar\.xz)' | head -1)
    
    if [ -z "$LATEST_VERSION" ]; then
        # Fallback versions if scraping fails
        LATEST_VERSION="13.5.1"
        echo -e "${YELLOW}[!] Could not fetch latest version, using fallback: $LATEST_VERSION${NC}"
    else
        echo -e "${GREEN}[+] Latest version: $LATEST_VERSION${NC}"
    fi
}

# Function to download and install TOR Browser
install_tor_browser() {
    echo -e "${BLUE}[*] Downloading TOR Browser...${NC}"
    cd /tmp
    
    # Try primary URL first
    TOR_URL="https://www.torproject.org/dist/torbrowser/${LATEST_VERSION}/tor-browser-linux-x86_64-${LATEST_VERSION}.tar.xz"
    
    echo -e "${YELLOW}[!] Downloading from: $TOR_URL${NC}"
    
    if ! wget -q --show-progress --timeout=30 "$TOR_URL" -O tor-browser.tar.xz 2>/dev/null; then
        echo -e "${YELLOW}[!] Primary download failed, trying mirror...${NC}"
        # Try archive mirror
        wget -q --show-progress "https://archive.torproject.org/tor-package-archive/torbrowser/${LATEST_VERSION}/tor-browser-linux-x86_64-${LATEST_VERSION}.tar.xz" -O tor-browser.tar.xz
    fi
    
    if [ ! -f tor-browser.tar.xz ] || [ ! -s tor-browser.tar.xz ]; then
        echo -e "${RED}[-] Download failed!${NC}"
        echo -e "${YELLOW}[!] Trying alternative download method...${NC}"
        
        # Try older version as fallback
        OLD_VERSION="13.0.15"
        wget -q --show-progress "https://archive.torproject.org/tor-package-archive/torbrowser/${OLD_VERSION}/tor-browser-linux-x86_64-${OLD_VERSION}.tar.xz" -O tor-browser.tar.xz
        
        if [ ! -f tor-browser.tar.xz ] || [ ! -s tor-browser.tar.xz ]; then
            echo -e "${RED}[-] All download attempts failed!${NC}"
            echo -e "${YELLOW}[!] Please check your internet connection or download manually${NC}"
            exit 1
        fi
    fi
    
    echo -e "${BLUE}[*] Installing TOR Browser...${NC}"
    sudo rm -rf /opt/tor-browser
    sudo tar -xf tor-browser.tar.xz -C /opt/
    sudo mv /opt/tor-browser /opt/tor-browser_temp
    sudo mv /opt/tor-browser_temp/* /opt/tor-browser
    sudo chown -R $USER:$USER /opt/tor-browser
    sudo ln -sf /opt/tor-browser/Browser/start-tor-browser /usr/local/bin/tor-browser
    
    # Clean up
    rm -f /tmp/tor-browser.tar.xz
}

# Function to create desktop entries
create_desktop_entries() {
    echo -e "${BLUE}[*] Creating desktop entries...${NC}"
    
    mkdir -p ~/.local/share/applications
    
    # TOR Browser desktop entry
    cat > ~/.local/share/applications/tor-browser.desktop << DESKTOP
[Desktop Entry]
Name=TOR Browser
GenericName=Web Browser
Comment=Browse the Internet anonymously
Exec=/opt/tor-browser/Browser/start-tor-browser %U
Icon=/opt/tor-browser/Browser/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
Categories=Network;WebBrowser;Security;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
DESKTOP
    
    # TOR Terminal Control desktop entry
    cat > ~/.local/share/applications/tor-terminal.desktop << DESKTOP
[Desktop Entry]
Name=TOR Terminal
Comment=Launch TOR-enabled terminal
Exec=gnome-terminal -- bash -c "echo 'TOR Terminal Active'; echo 'Check IP: curl --socks5 localhost:9050 ifconfig.me'; echo; export SOCKS5=localhost:9050; bash"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Network;System;
DESKTOP
    
    # TOR Monitor desktop entry (nyx)
    cat > ~/.local/share/applications/tor-monitor.desktop << DESKTOP
[Desktop Entry]
Name=TOR Monitor
Comment=Monitor TOR network status
Exec=gnome-terminal -- bash -c "nyx"
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=Network;System;
DESKTOP
}

# Function to create terminal helper scripts
create_terminal_scripts() {
    echo -e "${BLUE}[*] Creating TOR terminal helper scripts...${NC}"
    
    mkdir -p ~/.tor_scripts
    
    # TOR Start script
    cat > ~/.tor_scripts/tor-start.sh << 'START'
#!/bin/bash
echo "[+] Starting TOR service..."
sudo systemctl start tor
echo "[+] TOR started on localhost:9050"
echo "[+] Check your IP: curl --socks5 localhost:9050 ifconfig.me"
START
    chmod +x ~/.tor_scripts/tor-start.sh
    
    # TOR Stop script
    cat > ~/.tor_scripts/tor-stop.sh << 'STOP'
#!/bin/bash
echo "[+] Stopping TOR service..."
sudo systemctl stop tor
echo "[+] TOR stopped"
STOP
    chmod +x ~/.tor_scripts/tor-stop.sh
    
    # TOR Status script
    cat > ~/.tor_scripts/tor-status.sh << 'STATUS'
#!/bin/bash
echo "[+] TOR Service Status:"
sudo systemctl status tor --no-pager
echo
echo "[+] TOR Connection Test:"
if curl --socks5 localhost:9050 ifconfig.me -s -o /dev/null -w "Connected IP: %{remote_ip}\n"; then
    echo "✅ TOR is working"
else
    echo "❌ TOR is not responding"
fi
STATUS
    chmod +x ~/.tor_scripts/tor-status.sh
    
    # TOR Alias script
    cat > ~/.tor_scripts/tor-alias.sh << 'ALIAS'
#!/bin/bash
alias tor-start='sudo systemctl start tor'
alias tor-stop='sudo systemctl stop tor'
alias tor-status='sudo systemctl status tor'
alias tor-check='curl --socks5 localhost:9050 ifconfig.me'
alias tshell='torsocks bash'
ALIAS
    chmod +x ~/.tor_scripts/tor-alias.sh
    
    # Add to .bashrc if not already there
    if ! grep -q "tor-alias.sh" ~/.bashrc; then
        echo "source ~/.tor_scripts/tor-alias.sh" >> ~/.bashrc
        echo -e "${GREEN}[+] Added TOR aliases to ~/.bashrc${NC}"
    fi
}

# Function to create start menu scripts
create_start_scripts() {
    echo -e "${BLUE}[*] Creating start menu scripts...${NC}"
    
    # Interactive menu script
    cat > ~/.tor_scripts/tor-menu.sh << 'MENU'
#!/bin/bash
while true; do
    clear
    echo "═══════════════════════════════════════════════"
    echo "     🌐 TOR CONTROL MENU 🌐"
    echo "═══════════════════════════════════════════════"
    echo "1. Start TOR Service"
    echo "2. Stop TOR Service"
    echo "3. Check TOR Status"
    echo "4. Launch TOR Browser (GUI)"
    echo "5. Launch TOR Terminal (Shell)"
    echo "6. Open TOR Monitor (nyx)"
    echo "7. Check TOR IP"
    echo "8. Restart TOR Service"
    echo "9. Edit TOR Configuration"
    echo "0. Exit"
    echo "═══════════════════════════════════════════════"
    read -p "Choose an option: " choice
    
    case $choice in
        1) sudo systemctl start tor && echo "✅ TOR started"; sleep 2 ;;
        2) sudo systemctl stop tor && echo "✅ TOR stopped"; sleep 2 ;;
        3) sudo systemctl status tor --no-pager; read -p "Press Enter..." ;;
        4) tor-browser & ;;
        5) torsocks bash ;;
        6) nyx ;;
        7) curl --socks5 localhost:9050 ifconfig.me; read -p "Press Enter..." ;;
        8) sudo systemctl restart tor && echo "✅ TOR restarted"; sleep 2 ;;
        9) sudo nano /etc/tor/torrc ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option"; sleep 2 ;;
    esac
done
MENU
    chmod +x ~/.tor_scripts/tor-menu.sh
    
    # Create global symlink
    sudo ln -sf ~/.tor_scripts/tor-menu.sh /usr/local/bin/tor-menu
}

# Function to configure TOR
configure_tor() {
    echo -e "${BLUE}[*] Configuring TOR...${NC}"
    
    # Backup original config
    sudo cp /etc/tor/torrc /etc/tor/torrc.backup
    
    # Add common configurations
    sudo bash -c 'cat >> /etc/tor/torrc << EOF

# Custom TOR Configurations
SOCKSPort 9050
ControlPort 9051
CookieAuthentication 1
CookieAuthFileGroupReadable 1
RunAsDaemon 1
EOF'
    
    echo -e "${GREEN}[+] TOR configured. Original config backed up to /etc/tor/torrc.backup${NC}"
}

# Function to enable and start TOR
enable_tor() {
    echo -e "${BLUE}[*] Enabling and starting TOR service...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable tor --now
    sleep 2
    
    # Check if TOR is running
    if sudo systemctl is-active --quiet tor; then
        echo -e "${GREEN}[+] TOR service is active!${NC}"
    else
        echo -e "${YELLOW}[!] TOR service failed to start. Checking status...${NC}"
        sudo systemctl status tor --no-pager
    fi
}

# Function to test TOR
test_tor() {
    echo -e "${BLUE}[*] Testing TOR connection...${NC}"
    
    if curl --socks5-hostname localhost:9050 https://check.torproject.org/ -s -o /dev/null -w "%{http_code}" | grep -q "200"; then
        echo -e "${GREEN}[+] TOR is working properly!${NC}"
        echo -e "${GREEN}[+] Your TOR IP:${NC}"
        curl --socks5-hostname localhost:9050 https://check.torproject.org/ -s | grep -oP '"IP":\s*"\K[^"]+' || echo "Couldn't determine IP"
    else
        echo -e "${YELLOW}[!] TOR test failed. Please check your configuration.${NC}"
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
    echo "  tor-menu       - Interactive TOR menu (Recommended)"
    echo "  tor-browser    - Launch TOR Browser"
    echo "  tor-start      - Start TOR service"
    echo "  tor-stop       - Stop TOR service"
    echo "  tor-status     - Check TOR service status"
    echo "  tor-check      - Check your TOR IP"
    echo "  nyx            - Launch TOR monitor"
    echo "  tshell         - Launch TOR-enabled shell"
    echo
    echo -e "${BLUE}📁 Scripts Location:${NC} ~/.tor_scripts/"
    echo -e "${BLUE}📁 TOR Browser Location:${NC} /opt/tor-browser/"
    echo -e "${BLUE}📁 TOR Config Location:${NC} /etc/tor/torrc"
    echo
    echo -e "${BLUE}📌 Desktop Shortcuts Available:${NC}"
    echo "  TOR Browser    - Graphical browser"
    echo "  TOR Terminal   - TOR-enabled terminal"
    echo "  TOR Monitor    - Network monitor (nyx)"
    echo
    echo -e "${YELLOW}⚠️  After first launch:${NC}"
    echo "  1. TOR Browser will update itself on first run"
    echo "  2. Use 'tor-menu' for easy management"
    echo "  3. Check TOR connection with 'tor-check'"
    echo
    echo -e "${GREEN}┌───────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│  🌐 Stay Anonymous, Stay Safe! 🛡️  │${NC}"
    echo -e "${GREEN}└───────────────────────────────────────┘${NC}"
}

# Main installation function
main() {
    check_root
    check_internet
    
    echo -e "${YELLOW}[!] This will install TOR service and TOR Browser${NC}"
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
    create_start_scripts
    configure_tor
    enable_tor
    test_tor
    display_usage
    
    echo -e "${GREEN}[+] Installation complete!${NC}"
    echo -e "${YELLOW}[!] Run 'tor-menu' to get started${NC}"
}

# Run main function
main
