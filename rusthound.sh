#!/bin/bash
set -e

echo "🔄 RustHound-CE COMPLETE install (Rust + deps + binary)"

# 1) FULL Rust install first
echo "🛠️ Installing Rust + Cargo..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"

# Verify cargo works
cargo --version || { echo "❌ Rust install failed"; exit 1; }

# 2) Create target dir
echo "📁 Setting up /opt/rusthound..."
sudo mkdir -p /opt/rusthound && sudo chown -R $USER:$USER /opt/rusthound

# 3) Install ALL deps
echo "📦 Installing build dependencies..."
sudo apt update -qq
sudo apt install -y clang libclang-dev libkrb5-dev krb5-user libsasl2-modules-gssapi-mit \
  build-essential pkg-config libssl-dev libgss-dev

# 4) Fix gssapi headers
GSSAPI_PATH=$(find /usr -name "gssapi.h" 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "/usr/include/gssapi")
export C_INCLUDE_PATH="$GSSAPI_PATH:$C_INCLUDE_PATH"
export BINDGEN_EXTRA_CLANG_ARGS="-I$GSSAPI_PATH"
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"

# 5) Clean + install RustHound-CE
echo "📥 Installing RustHound-CE..."
rm -rf /tmp/cargo-install*
cargo install rusthound-ce --force --locked --root /opt/rusthound

# 6) Symlink + PATH
mkdir -p "$HOME/bin"
ln -sf /opt/rusthound/bin/rusthound-ce "$HOME/bin/rusthound-ce"
echo 'export PATH="$HOME/bin:/opt/rusthound/bin:$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "✅ RustHound-CE ready! $(rusthound-ce --help | head -1)"
