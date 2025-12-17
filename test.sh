sudo apt remove --purge ghidra -y && sudo apt autoremove -y
# 1. Kill duplicate seclists (1.7GB) - you have clean /opt/SecLists
sudo apt remove --purge seclists -y && sudo apt autoremove -y

# 2. APT caches (2-5GB)
sudo apt clean && sudo apt autoclean && sudo rm -rf /var/cache/apt/archives/*

# 3. Logs/temp (1GB)
sudo find /var/log -type f -delete && sudo rm -rf /tmp/* /var/tmp/* ~/.cache/*

df -h /
