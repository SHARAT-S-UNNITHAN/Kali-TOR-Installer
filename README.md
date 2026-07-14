```bash
cd ~/github-scripts

cat > README.md << 'EOF'
# 🧅 Kali TOR Installer

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-Kali%20Linux-red)
![License](https://img.shields.io/badge/license-MIT-green)

### Fixes the infamous "Package torbrowser-launcher has no installation candidate" error on Kali Linux

---

## ❌ The Problem

When you try to install TOR Browser on Kali Linux using the official method:

```bash
sudo apt update
sudo apt install torbrowser-launcher
```

You get this error:
```
Package torbrowser-launcher is not available, but is referred to by another package.
Error: Package 'torbrowser-launcher' has no installation candidate
```

**Why?** Kali Linux removed `torbrowser-launcher` from their repositories, but the official documentation still tells users to use it. This leaves many Kali users stuck.

---

## ✅ The Solution

This script bypasses the broken package and installs everything directly from the official Tor Project sources.

### One-Line Install
```bash
git clone https://github.com/SHARAT-S-UNNITHAN/Kali-TOR-Installer.git && cd Kali-TOR-Installer && chmod +x tor-installer.sh && ./tor-installer.sh
```

### Step-by-Step
```bash
git clone https://github.com/SHARAT-S-UNNITHAN/Kali-TOR-Installer.git
cd Kali-TOR-Installer
chmod +x tor-installer.sh
./tor-installer.sh
```

---

## 📦 What Gets Installed

| Package | Purpose |
|---------|---------|
| `tor` | TOR service daemon |
| `torsocks` | Route apps through TOR |
| `tor-geoipdb` | GeoIP database for exit nodes |
| `obfs4proxy` | Bridge support for censored regions |
| `nyx` | Terminal-based TOR monitor |
| TOR Browser | Latest version from Tor Project |

---

## 🚀 After Installation

```bash
# Launch TOR Browser
tor-browser

# Monitor TOR network
nyx

# Check TOR service status
sudo systemctl status tor

# Test TOR connection
torsocks curl https://check.torproject.org/api/ip
```

---

## 🔧 Features

- ✅ Works on Kali Linux 2023.x, 2024.x, 2025.x
- ✅ Downloads TOR Browser directly from Tor Project
- ✅ Multiple fallback URLs if download fails
- ✅ Creates desktop entry (Applications → Internet → TOR Browser)
- ✅ Creates `tor-browser` command for terminal launch
- ✅ Installs Nyx monitor for real-time TOR visualization
- ✅ Configures TOR service to start on boot
- ✅ Sets proper file permissions

---

## 📁 Files

```
Kali-TOR-Installer/
├── tor-installer.sh    # Main installation script
└── README.md           # This file
```

---

## 🧪 Tested On

| OS | Version | Status |
|----|---------|--------|
| Kali Linux | 2024.4 | ✅ Working |
| Kali Linux | 2024.3 | ✅ Working |
| Kali Linux | 2024.2 | ✅ Working |
| Kali Linux | 2023.4 | ✅ Working |

---

## ⚠️ Notes

- Requires internet connection to download TOR Browser
- TOR Browser is ~100MB download
- Not for use as root - run as normal user
- TOR may be slow - this is normal (traffic routed through multiple relays)

---

## 🔄 Updating TOR Browser

To update TOR Browser later, simply run the script again:
```bash
./tor-installer.sh
```
It will download and install the latest version.

---

## 📝 License

MIT License - see [LICENSE](LICENSE) file

---

## 👤 Author

**Sharat S Unnithan**

- GitHub: [@SHARAT-S-UNNITHAN](https://github.com/SHARAT-S-UNNITHAN)
- LinkedIn: [sharat-s-unnithan](https://linkedin.com/in/sharat-s-unnithan-b363852a7)

---

## ⭐ Support

If this helped you, please star the repo! It helps others find this solution.

## 🐛 Issues

Found a bug? [Open an issue](https://github.com/SHARAT-S-UNNITHAN/Kali-TOR-Installer/issues)

---



