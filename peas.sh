#!/bin/bash
set -e

echo "🔄 PEAS download (simple)"

# Setup /opt
echo "📁 Creating /opt..."
sudo mkdir -p /opt/{linpeas,winpeas}
sudo chown -R $(whoami):$(whoami) /opt/{linpeas,winpeas}

# Get latest build
BUILD=$(curl -s https://github.com/peass-ng/PEASS-ng/releases | grep -oi "refs/heads/master.*20[0-9]\{6\}-[a-f0-9]\{8\}" | head -1)
URL="https://github.com/peass-ng/PEASS-ng/releases/download/$BUILD"

cd /opt/linpeas
echo "📥 LinPEAS..."
curl -sL $URL/linpeas*.{sh,linux*} -O
chmod +x *.sh *.linux*

cd /opt/winpeas  
echo "📥 WinPEAS..."
curl -sL $URL/winPEAS* -O
chmod +x *.exe *.bat 2>/dev/null || true

echo "🎉 Done!"
echo "/opt/linpeas/  /opt/winpeas/"
ls -la /opt/{linpeas,winpeas}/
