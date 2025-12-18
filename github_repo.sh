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
    git clone --depth 1 https://github.com/danielmiessler/SecLists.git . || \
    git clone https://github.com/danielmiessler/SecLists.git .
else
    # Fallback to zip
    wget -q https://github.com/danielmiessler/SecLists/archive/refs/heads/master.zip -O SecLists.zip
    unzip -q SecLists.zip
    mv SecLists-master/* . 2>/dev/null || true
    mv SecLists-master/.* . 2>/dev/null || true
    rm -rf SecLists-master SecLists.zip
fi

# Show INITIAL size BEFORE extraction and cleanup
echo "📏 INITIAL SecLists size:"
INITIAL_SIZE=$(du -sh "$SECLISTS_DIR" | cut -f1)
echo "   $INITIAL_SIZE"

# Extract rockyou.txt.tar.gz BEFORE cleaning (same folder as the archive)
echo "📦 Extracting rockyou.txt.tar.gz..."
ROCKYOU_TAR="$SECLISTS_DIR/Passwords/Leaked-Databases/rockyou.txt.tar.gz"
ROCKYOU_DIR="$(dirname "$ROCKYOU_TAR")"
ROCKYOU_FILE="$ROCKYOU_DIR/rockyou.txt"

if [ -f "$ROCKYOU_TAR" ]; then
    # First extract the outer tar.gz, then the inner tar.gz
    tar -xzf "$ROCKYOU_TAR" -C "$ROCKYOU_DIR" >/dev/null 2>&1 || true
    # Handle the inner rockyou.txt.tar.gz if it exists
    INNER_TAR="$ROCKYOU_DIR/rockyou.txt.tar.gz"
    if [ -f "$INNER_TAR" ]; then
        tar -xzf "$INNER_TAR" -C "$ROCKYOU_DIR" >/dev/null 2>&1 || true
        rm -f "$INNER_TAR"  # Remove inner archive after extraction
    fi
    
    if [ -f "$ROCKYOU_FILE" ]; then
        echo "✅ rockyou.txt extracted to $ROCKYOU_DIR ($(wc -l < "$ROCKYOU_FILE" 2>/dev/null) lines)"
    else
        echo "⚠️  rockyou.txt not found after extraction from $ROCKYOU_TAR"
        ls -la "$ROCKYOU_DIR" | grep -i rockyou || true
    fi
else
    echo "⚠️  rockyou.txt.tar.gz not found at $ROCKYOU_TAR"
fi

# Clean ONLY compressed files AFTER extraction (leave rockyou.txt and all dirs/files)
echo "🧹 Cleaning compressed files (space optimization)..."
find "$SECLISTS_DIR" \
    -type f \( -name "*.tar" -o -name "*.tar.gz" -o -name "*.tgz" -o -name "*.zip" -o -name "*.gz" -o -name "*.7z" \) \
    ! -name "rockyou.txt" -delete 2>/dev/null || true

# Show FINAL size AFTER cleanup
echo "📏 FINAL SecLists size:"
FINAL_SIZE=$(du -sh "$SECLISTS_DIR" | cut -f1)
echo "   $FINAL_SIZE (was $INITIAL_SIZE)"
echo "✅ Space saved! Archives removed."

# Create symlink to /usr/share/wordlists/ (standard wordlist location)
echo "🔗 Creating symlink rockyou.txt → /usr/share/wordlists/..."
sudo mkdir -p /usr/share/wordlists
# Remove existing symlink if present
sudo rm -f /usr/share/wordlists/rockyou.txt
# Create new symlink (requires sudo for /usr/share)
sudo ln -sf "$ROCKYOU_FILE" /usr/share/wordlists/rockyou.txt
echo "✅ Symlink created: /usr/share/wordlists/rockyou.txt → $ROCKYOU_FILE"

# Final verification
if [ -f "$ROCKYOU_FILE" ]; then
    echo "✅ rockyou.txt verified: $(wc -l < "$ROCKYOU_FILE") lines"
    echo "📂 Passwords directory sample:"
    ls "$SECLISTS_DIR/Passwords/" | head -3 2>/dev/null || true
    echo "🔍 Symlink test: $(readlink -f /usr/share/wordlists/rockyou.txt 2>/dev/null || echo 'Not accessible')"
else
    echo "⚠️  rockyou.txt still missing - check $ROCKYOU_DIR manually"
fi

cd ~
echo "🎉 SecLists ready at $SECLISTS_DIR with /usr/share/wordlists/rockyou.txt symlink!"
