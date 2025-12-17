#!/bin/bash
set -e

USER=$(whoami)
echo "🔄 FINAL evil-winrm install for $USER (gem latest + apt cleanup)"

# Cleanup existing installations
echo "🧹 Removing apt evil-winrm..."
apt remove evil-winrm -y 2>/dev/null || true
rm -f /usr/bin/evil-winrm /usr/local/bin/evil-winrm "$HOME/bin/evil-winrm" 2>/dev/null || true

# Remove old gems (user + system)
echo "💎 Removing old evil-winrm gems..."
gem uninstall evil-winrm -a -x 2>/dev/null || true

# Setup USER gem dir (no sudo needed)
echo "🏠 Setting up user gem directory..."
mkdir -p ~/.gem/ruby/$(ruby -e 'print RUBY_VERSION[/\A\d+\.\d+/]')/bin
echo 'gem: --user-install --no-document' > ~/.gemrc

# Update gem + install latest (USER mode)
echo "🔄 Updating gems + installing evil-winrm..."
gem update --system --no-document 2>/dev/null || true
gem install evil-winrm --no-document

# Symlink to user bin (priority)
echo "🔗 Creating symlink..."
mkdir -p "$HOME/bin"
rm -f "$HOME/bin/evil-winrm" 2>/dev/null || true

GEM_BIN=$(ruby -e 'puts Gem.bindir')
ln -sf "$GEM_BIN/evil-winrm" "$HOME/bin/evil-winrm"

# PATH fix ($HOME/bin first)
echo "⚙️  Fixing PATH..."
sed -i '/export PATH=/d' ~/.bashrc
echo 'export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/snap/bin:$PATH"' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/.gem"' >> ~/.bashrc
echo 'export PATH="$HOME/.gem/ruby/*/bin:$PATH"' >> ~/.bashrc

source ~/.bashrc

echo "✅ evil-winrm v3.9 ready globally!"
echo "🎉 Test:"
evil-winrm -V

echo "🎉 Restarting shell in ~/my_data/automation..."
cd ~/my_data/automation || cd ~
