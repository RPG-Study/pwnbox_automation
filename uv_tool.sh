#!/bin/bash
set -e

echo "🔧 Installing / refreshing AD tools via uv"

# 1) Install uv
echo "📦 Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Make sure uv is on PATH for this script
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

echo "🧹 Removing system Certipy..."
sudo rm /usr/local/bin/certipy* /usr/bin/certipy* 2>/dev/null || true
sudo apt remove -y python3-certipy certipy 2>/dev/null || true
sudo pip3 uninstall -y certipy 2>/dev/null || true

echo "📥 Installing latest Certipy with uv..."
uv tool install "git+https://github.com/ly4k/Certipy"

echo "🧹 Removing system Impacket..."
sudo rm /usr/local/bin/impacket* /usr/bin/impacket* 2>/dev/null || true
sudo apt remove -y python3-impacket impacket 2>/dev/null || true
sudo apt autoremove -y 2>/dev/null || true

echo "📥 Installing latest Impacket with uv..."
uv tool install "git+https://github.com/fortra/impacket"

echo "🧹 Removing system NetExec / nxc..."
sudo rm /usr/local/bin/nxc /usr/local/bin/netexec 2>/dev/null || true

echo "📥 Installing latest NetExec (nxc) with uv..."
uv tool install "git+https://github.com/Pennyw0rth/NetExec"

echo "🧹 Removing system BloodyAD..."
sudo rm /usr/local/bin/bloodyAD /usr/bin/bloodyAD 2>/dev/null || true
sudo apt remove -y bloodyad python3-bloodyad 2>/dev/null || true
sudo pip3 uninstall -y bloodyAD 2>/dev/null || true

echo "📥 Installing latest BloodyAD with uv..."
uv tool install "git+https://github.com/CravateRouge/bloodyAD" --with minikerberos

echo "🧠 Clearing bash command cache..."
hash -r || true

echo "✅ uv tool setup finished!"
