#!/bin/bash
# TOR Installer for Kali Linux
# Fixes: "Package torbrowser-launcher has no installation candidate"
# Created By: Sharat S Unnithan

set -e

echo "[*] Installing TOR service..."
sudo apt update -qq
sudo apt install -y tor torsocks tor-geoipdb obfs4proxy nyx

echo "[*] Downloading TOR Browser..."
cd /tmp
wget -q --show-progress "https://www.torproject.org/dist/torbrowser/13.5.1/tor-browser-linux-x86_64-13.5.1.tar.xz" -O tor-browser.tar.xz 2>/dev/null || \
wget -q --show-progress "https://archive.torproject.org/tor-package-archive/torbrowser/13.0.15/tor-browser-linux-x86_64-13.0.15.tar.xz" -O tor-browser.tar.xz

echo "[*] Installing TOR Browser..."
sudo rm -rf /opt/tor-browser
sudo tar -xf tor-browser.tar.xz -C /opt/
sudo chown -R $USER:$USER /opt/tor-browser
sudo ln -sf /opt/tor-browser/Browser/start-tor-browser /usr/local/bin/tor-browser

mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/tor-browser.desktop << DESKTOP
[Desktop Entry]
Name=TOR Browser
Exec=/opt/tor-browser/Browser/start-tor-browser
Icon=/opt/tor-browser/Browser/browser/chrome/icons/default/default128.png
Terminal=false
Type=Application
Categories=Network;Security;
DESKTOP

sudo systemctl enable tor --now
rm /tmp/tor-browser.tar.xz

echo "[+] Done! Run: tor-browser"
echo "[+] Monitor: nyx"
