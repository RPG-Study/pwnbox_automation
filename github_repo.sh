#!/bin/bash
set -e

USER=$(whoami)
echo "🔄 FINAL SecLists install for $USER (pwnbox safe + latest guaranteed)"

# Cleanup ALL
echo "🧹 Removing existing SecLists..."
rm -rf /usr/src/SecLists "$HOME/SecLists" "$HOME/opt/SecLists" /opt/SecLists "$HOME/bin/seclists" 2>/dev/null || true

# Smart dir setup - /opt/ ONLY
echo "📁 Setting up SecLists directory..."
sudo mkdir -p /opt/SecLists
sudo chown -R "$USER:$USER" /opt/SecLists
SECLISTS_DIR="/opt/SecLists"
echo "✅ Using $SECLISTS_DIR"

cd "$SECLISTS_DIR"
rm -rf * .[^.]* .??* 2>/dev/null || true

# Download latest SecLists via git (fast + complete)
echo "📥 Downloading latest SecLists..."
if command -v git >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/danielmiessler/SecLists.git . || git clone https://github.com/danielmiessler/SecLists.git .
else
    # Fallback to zip
    wget -q https://github.com/danielmiessler/SecLists/archive/refs/heads/master.zip -O SecLists.zip
    unzip -q SecLists.zip
    mv SecLists-master/* . 2>/dev/null || true
    mv SecLists-master/.* . 2>/dev/null || true
    rm -rf SecLists-master SecLists.zip
fi

# Extract rockyou.txt BEFORE cleaning (protect it)
echo "📦 Extracting rockyou.txt..."
ROCKYOU_TAR="/opt/SecLists/Passwords/Leaked-Databases/rockyou.tar.gz"
ROCKYOU_FILE="/opt/SecLists/Passwords/Leaked-Databases/rockyou.txt"
if [ -f "$ROCKYOU_TAR" ]; then
    tar -xzf "$ROCKYOU_TAR" -C /opt/SecLists/Passwords/Leaked-Databases/ --wildcards "*rockyou.txt" >/dev/null 2>&1 || \
    tar -xzf "$ROCKYOU_TAR" -C /opt/SecLists --wildcards "*rockyou.txt" >/dev/null 2>&1 || true
    [ -f "$ROCKYOU_FILE" ] && echo "✅ rockyou.txt extracted & protected"
fi

# Clean ALL tar/zip/gz files - EXCLUDE rockyou.txt
echo "🧹 Cleaning compressed files (space optimization)..."
find /opt/SecLists -name "*.tar*" ! -name "rockyou.txt" -delete \
  -o -name "*.zip" -delete \
  -o -name "*.gz" ! -name "rockyou.txt" -delete \
  -o -name "*.7z" -delete 2>/dev/null || true
echo "✅ All archives removed (~$(du -sh /opt/SecLists | cut -f1))"

# Verify rockyou exists
if [ -f "$ROCKYOU_FILE" ]; then
    echo "✅ rockyou.txt: $(wc -l < "$ROCKYOU_FILE" 2>/dev/null) lines"
    ls /opt/SecLists/Passwords/ | head -3
else
    echo "⚠️  rockyou.txt not found - check Passwords/Leaked-Databases/"
fi

cd ~ 
echo "🎉 SecLists ready at $SECLISTS_DIR"
