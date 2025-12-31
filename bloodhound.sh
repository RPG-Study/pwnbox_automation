#!/bin/bash
set -e

USER=$(whoami)
echo "🔄 BloodHound + Neo4j install for $USER (pwnbox safe)"

# Bulletproof cleanup - dpkg force + apt (handles Parrot OS stubborn packages)
echo "🧹 FORCE removing stubborn Neo4j/BloodHound packages..."
sudo dpkg --purge --force-all neo4j cypher-shell bloodhound 2>/dev/null || true
sudo apt purge -y neo4j neo4j-browser neo4j-server bloodhound cypher-shell || true
sudo apt autoremove -y

# Double-check with dpkg force (Parrot OS fix)
echo "🔧 Double-checking package removal..."
sudo dpkg --configure -a || true
sudo dpkg --purge --force-all neo4j cypher-shell bloodhound 2>/dev/null || true

# Delete ALL data directories (35GB+ cleanup)
echo "🗑️  Deleting data directories..."
sudo rm -rf /var/lib/neo4j /etc/neo4j /opt/neo4j /usr/share/neo4j /usr/lib/neo4j \
            /usr/lib/bloodhound "$HOME/neo4j" /opt/bloodhound

# Remove binaries + desktop entries
sudo rm -f /usr/bin/neo4j /usr/bin/bloodhound "$HOME/bin/bloodhound" /usr/local/bin/bloodhound
sudo rm -f /usr/share/applications/*bloodhound*.desktop /usr/share/applications/*neo4j*.desktop 2>/dev/null || true

echo "✅ Native cleanup complete (~36GB freed)"

# Smart dir setup (pwnbox safe)
echo "📁 Setting up BloodHound directory..."
if sudo mkdir -p /opt/bloodhound/server 2>/dev/null && sudo chown -R "$USER:$USER" /opt/bloodhound; then
    BH_DIR="/opt/bloodhound"
    echo "✅ Using /opt/bloodhound (system-wide)"
    sudo chown -R "$USER:$USER" /opt/bloodhound
else
    mkdir -p "$HOME/opt/bloodhound/server"
    BH_DIR="$HOME/opt/bloodhound"
    echo "✅ Using $BH_DIR (pwnbox safe)"
fi

cd "$BH_DIR/server"

# Safe cleanup - only specific files, no aggressive *
sudo rm -f docker-compose.yaml initial-password.txt .docker-compose* 2>/dev/null || true

# Download composer file
echo "📥 Downloading BloodHound Community Edition..."
sudo curl -sL "https://ghst.ly/getbhce" -o docker-compose.yaml
sudo chown "$USER:$USER" docker-compose.yaml

# Change port from 8080 → 8088
echo "⚙️  Changing BloodHound port to 8088..."
sudo sed -i 's|BLOODHOUND_PORT:-8080|BLOODHOUND_PORT:-8088|g' docker-compose.yaml

# Start docker
sudo systemctl start docker

# Pull and start BloodHound (docker-compose v2 style)
echo "🚀 Starting BloodHound + Neo4j..."
sudo docker compose pull
sudo docker compose up -d

# Wait for Neo4j to be ready (port 7474)
echo "⏳ Waiting for Neo4j (max 5min)..."
timeout=300; delay=10; elapsed=0
while ! sudo nc -z localhost 7474 2>/dev/null; do
    sleep $delay
    elapsed=$((elapsed + delay))
    if [ $elapsed -ge $timeout ]; then
        echo "❌ Neo4j timeout after ${timeout}s"
        exit 1
    fi
    echo "⏳ Neo4j not ready yet... ($elapsed/$timeout)"
done
echo "✅ Neo4j ready on port 7474!"

# Grab BloodHound password
echo "🔑 Extracting BloodHound password..."
sleep 10
BH_PASS=$(sudo docker compose logs bloodhound 2>/dev/null | grep -oP "Password Set To:\s+\K[\S]+" | tail -1)

if [ -n "$BH_PASS" ]; then
    cat > initial-password.txt << EOF
username: admin
password: $BH_PASS
EOF
    echo "✅ Password saved to initial-password.txt:"
    cat initial-password.txt
else
    echo "⚠️  No password found in logs, check manually:"
    sudo docker compose logs bloodhound | grep -i password
fi

# 🔍 DEBUG: Verify cleanup success
echo
echo "🔍 DEBUG: Checking cleanup status..."
echo "======================================"
echo "📦 Native packages remaining:"
dpkg -l | grep -E 'neo4j|bloodhound' || echo "✅ NO native packages found!"

echo -e "\n🔍 Neo4j directories:"
sudo du -sh /var/lib/neo4j /usr/share/neo4j /usr/lib/neo4j 2>/dev/null || echo "✅ NO Neo4j directories found!"

echo -e "\n🔍 BloodHound binaries:"
which bloodhound neo4j 2>/dev/null || echo "✅ NO native binaries found!"

echo -e "\n🔍 Docker status (should show ~1.7GB):"
sudo docker system df

echo -e "\n🔍 BloodHound CE containers:"
sudo docker compose ps

# Final status
echo
echo "🎉 BloodHound CE ready! (Docker only)"
echo "📍 Directory: $BH_DIR/server"
echo "🌐 Neo4j:     http://localhost:7474"
echo "🌐 BloodHound: http://localhost:8088"
echo "⚙️  Control:   cd $BH_DIR/server && sudo docker compose {up,down,logs}"
echo "🔑 Password:  See initial-password.txt"

cd ~/my_data || cd ~
echo "✅ Script complete! Check df -h for space savings."
