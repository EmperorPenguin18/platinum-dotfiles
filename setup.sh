#Run this once you have updated your system and run raspi-config

#Check if script has root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

#Set a static IP address
echo "interface eth0" >> /etc/dhcpcd.conf
echo "static ip_address=192.168.0.30/24" >> /etc/dhcpcd.conf
echo "static routers=192.168.0.1" >> /etc/dhcpcd.conf
echo "static domain_name_servers=1.1.1.1" >> /etc/dhcpcd.conf

#Install all necessary things
apt-get install -y rclone openvpn qbittorrent-nox unzip jq apt-transport-https

#Setup rclone mount
echo "user_allow_other" >> /etc/fuse.conf
mv ./rclone.conf /mnt/rclone.conf
mkdir /mnt/Cloud
mv ./rclone.service /etc/systemd/system/rclone.service

#Setup mergerfs
wget 'https://github.com/trapexit/mergerfs/releases/download/2.29.0/mergerfs_2.29.0.debian-buster_armhf.deb'
dpkg -i mergerfs_2.29.0.debian-buster_armhf.deb
rm mergerfs_2.29.0.debian-buster_armhf.deb
mkdir /mnt/Local
mkdir /mnt/Local/TV
mkdir /mnt/Local/Movies
mkdir /mnt/MergerFS
mv ./mergerfs.service /etc/systemd/system/mergerfs.service

#Setup VPN
wget https://account.surfshark.com/api/v1/server/configurations
unzip configurations -d /etc/openvpn/
rm configurations
sed -i 's/auth-user-pass/auth-user-pass pass.txt/g' /etc/openvpn/ca-tor.prod.surfshark.com_udp.ovpn
mv ./pass.txt /etc/openvpn/pass.txt
mv ./openvpn.service /etc/systemd/system/openvpn.service

#Prevent IP leaks
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.eth0.disable_ipv6=1" >> /etc/sysctl.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf
mv ./dnsleaktest.sh ../dnsleaktest.sh
chmod +x ../dnsleaktest.sh

#Setup torrent client
mkdir /mnt/Downloads
mv ./qbittorrent.service /etc/systemd/system/qbittorrent.service

#Install Jackett
wget 'https://github.com/Jackett/Jackett/releases/download/v0.16.916/Jackett.Binaries.LinuxARM32.tar.gz'
tar -xvzf Jackett.Binaries.LinuxARM32.tar.gz
rm Jackett.Binaries.LinuxARM32.tar.gz
mv Jackett ../Jackett
../Jackett/install_service_systemd.sh

#Install Sonarr
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493
echo "deb http://apt.sonarr.tv/ master main" | sudo tee /etc/apt/sources.list.d/sonarr.list
apt update
apt install -y nzbdrone
mv ./sonarr.service /etc/systemd/system/sonarr.service

#Install Radarr
curl -L -O $( curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4 )
tar -xvzf Radarr.develop.*.linux.tar.gz
mv Radarr /opt
rm Radarr.develop.*.linux.tar.gz
mv ./radarr.service /etc/systemd/system/radarr.service

#Setup nightly uploads
echo "0 2 * * * root /usr/bin/timeout -k 5 6h /usr/bin/rclone move -P /mnt/Local encrypted: --exclude-from *partial~ --delete-empty-src-dirs --min-age 1d /etc/cron.daily" > /etc/crontab

#Install Jellyfin
wget -O - https://repo.jellyfin.org/jellyfin_team.gpg.key | apt-key add -
echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$( awk -F'=' '/^ID=/{ print $NF }' /etc/os-release ) $( awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release ) main" | tee /etc/apt/sources.list.d/jellyfin.list
apt update
apt install jellyfin

#Install Ombi
echo "deb [arch=amd64,armhf] http://repo.ombi.turd.me/stable/ jessie main" | tee "/etc/apt/sources.list.d/ombi.list"
wget -qO - https://repo.ombi.turd.me/pubkey.txt | apt-key add -
apt update
apt install ombi

#Cleanup
cd ../
mv ./MediaServer/setup.sh ./setup.sh
rm -r MediaServer
systemctl daemon-reload
systemctl enable rclone
systemctl enable mergerfs
systemctl enable --now openvpn
systemctl enable qbittorrent
systemctl enable sonarr
systemctl enable radarr
systemctl enable jellyfin
systemctl enable ombi
./dnsleaktest.sh
sleep 5
reboot
