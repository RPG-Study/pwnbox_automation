#!/bin/bash
set -e

echo "🧹 FULL CLEANUP - Removing temp files (with sudo)..."

# Clean /tmp completely
echo "🗑️  Cleaning /tmp..."
sudo rm -rf /tmp/* /tmp/.[!.]* /tmp/..?* 2>/dev/null || true

# Clean /usr/share/wordlists completely  
echo "🗑️  Cleaning /usr/share/wordlists..."
sudo rm -rf /usr/share/wordlists/* /usr/share/wordlists/.[!.]* /usr/share/wordlists/..?* 2>/dev/null || true

# Clean /opt completely (files + folders)
echo "🗑️  Cleaning /opt..."
sudo rm -rf /opt/* /opt/.[!.]* /opt/..?* 2>/dev/null || true

# Uninstall seclists (APT package)
echo "📦 Uninstalling SecLists package..."
sudo apt-get remove --purge -y seclists 2>/dev/null || true

# Uninstall Ghidra (if installed manually or in /opt)
echo "💥 Uninstalling Ghidra..."
sudo rm -rf /opt/ghidra* 2>/dev/null || true
sudo apt-get remove --purge -y ghidra 2>/dev/null || true

# Run autoremove to clean up unused dependencies
echo "🧽 Running autoremove..."
sudo apt-get autoremove -y 2>/dev/null || true
sudo apt-get autoclean -y 2>/dev/null || true

echo "✅ Cleanup complete!"
