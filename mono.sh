#!/bin/bash

echo "🔄 Updating package lists..."
sudo apt update

echo "📦 Installing Mono Complete... ⏳"
sudo apt install -f -y mono-complete

if [ $? -eq 0 ]; then
    echo "✅ Mono installed successfully! 🎉"
    echo "🔍 Verifying installation..."
    mono --version
    echo "🚀 Ready to run .NET binaries! 💪"
else
    echo "❌ Installation failed! 😞"
    exit 1
fi
