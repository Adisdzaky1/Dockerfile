#!/bin/bash

# Set warna
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Setup Neofetch config dari GitHub
mkdir -p /home/container/.config/neofetch
wget -qO /home/container/.config/neofetch/config.conf "https://raw.githubusercontent.com/Adisdzaky1/egg-conf/main/config.conf"

# Pastikan ownership yang benar
chown -R container:container /home/container
chown -R container:container /home/container/.config
chmod 755 /home/container/.config/neofetch


# =============================================
# VALIDASI IP PANEL DARI DATABASE GITHUB
# =============================================

echo -e "${CYAN}Memulai validasi IP panel...${NC}"

# URL database IP yang diizinkan (raw GitHub)
IP_DATABASE_URL="https://raw.githubusercontent.com/Adisdzaky1/egg-conf/main/allowed_ips.json"

# Mengambil IP publik server
PUBLIC_IP=$(curl -s https://api.ipify.org)
if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}Gagal mendapatkan IP publik!${NC}"
    exit 1
fi

echo -e "${YELLOW}IP Server:${NC} $PUBLIC_IP"

# Mengambil dan validasi database IP langsung dari GitHub
VALID_IP=$(curl -s "$IP_DATABASE_URL" | node -e "
const ip = '$PUBLIC_IP';
let dbData = '';
process.stdin.on('data', data => dbData += data);
process.stdin.on('end', () => {
    try {
        const db = JSON.parse(dbData);
        if (!Array.isArray(db)) throw new Error('Format database tidak valid');
        console.log(db.includes(ip) ? 'VALID' : 'INVALID');
    } catch (e) {
        console.error('ERROR:' + e.message);
        process.exit(1);
    }
});
")

# Hasil validasi
if [ "$VALID_IP" = "VALID" ]; then
    echo -e "${GREEN}IP terdaftar di database!${NC}"
elif [ "$VALID_IP" = "INVALID" ]; then
    echo -e "${RED}==================================================${NC}"
    echo -e "${RED}IP TIDAK TERDAFTAR DI DATABASE RESMI!${NC}"
    echo -e "${RED}Hubungi penyedia layanan untuk informasi lebih lanjut${NC}"
    echo -e "${RED}==================================================${NC}"
    exit 1
else
    echo -e "${RED}Error dalam validasi: $VALID_IP${NC}"
    exit 1
fi

sleep 1

clear
neofetch --config /home/container/.config/neofetch/config.conf

# Script Tambahan untuk Menjalankan Server
cd /home/container

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Print Node.js Version
echo -e "${GREEN}Node.js Version:${NC} $(node -v)"
sleep 1


# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')


# Jalankan Server
echo -e "${YELLOW}Starting the server...${NC}"
curl -s -O https://raw.githubusercontent.com/Adisdzaky1/egg-conf/main/run.js
curl -s -O https://raw.githubusercontent.com/Adisdzaky1/egg-conf/main/README-PANEL
eval ${MODIFIED_STARTUP}

# Jalankan perintah bawaan container
exec "$@"

