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

echo "✅ Cleanup complete!"
