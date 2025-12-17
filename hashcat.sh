#!/bin/bash
set -e

USER=$(whoami)
echo "🔄 FINAL Hashcat install for $USER (pwnbox safe + v7.1.2 guaranteed)"

# Cleanup ALL
echo "🧹 Removing existing hashcat..."
rm -rf /usr/src/hashcat "$HOME/hashcat" "$HOME/opt/hashcat" /opt/hashcat /usr/local/{bin,share}/hashcat* "$HOME/bin/hashcat" 2>/dev/null || true

# Smart dir setup
echo "📁 Setting up hashcat directory..."
if sudo mkdir -p /opt/hashcat 2>/dev/null && sudo chown -R "$USER:$USER" /opt/hashcat; then
    HASHCAT_DIR="/opt/hashcat"
    echo "✅ Using /opt/hashcat"
else
    mkdir -p "$HOME/opt/hashcat"
    HASHCAT_DIR="$HOME/opt/hashcat"
    echo "✅ Using $HASHCAT_DIR (pwnbox safe)"
fi

cd "$HASHCAT_DIR"
rm -rf * .[^.]* .??* 2>/dev/null || true

# Download latest v7.1.2 (FIXED)
echo "📥 Downloading latest v7.1.2..."
LATEST_URL=$(curl -s https://api.github.com/repos/hashcat/hashcat/releases/latest | grep '"browser_download_url"' | grep -i 7z | head -1 | cut -d '"' -f 4)
wget -q "$LATEST_URL" -O hashcat.7z || curl -L "$LATEST_URL" -o hashcat.7z
7z x hashcat.7z -y > /dev/null 2>&1
rm hashcat.7z

# Extract + rename (FIXED)
echo "📦 Extracting + preparing binary..."
HASHCAT_SUBDIR=$(find . -maxdepth 1 -type d -name "hashcat-*" | head -1)
[ -n "$HASHCAT_SUBDIR" ] && {
    mv "$HASHCAT_SUBDIR"/* . 2>/dev/null || true
    mv "$HASHCAT_SUBDIR"/.* . 2>/dev/null || true  # FIXED variable
    rm -rf "$HASHCAT_SUBDIR"
}

[ -x "hashcat.bin" ] && mv hashcat.bin hashcat && chmod +x hashcat && echo "✅ Renamed hashcat.bin → hashcat"

# Symlink + PATH
echo "🔗 Creating symlink..."
mkdir -p "$HOME/bin"
ln -sf "$HASHCAT_DIR/hashcat" "$HOME/bin/hashcat"

echo "⚙️  Fixing PATH..."
sed -i '/export PATH=/d' ~/.bashrc
echo 'export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/snap/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

hashcat --version && echo "✅ Hashcat ready globally!"
cd ~/my_data/automation || cd ~
