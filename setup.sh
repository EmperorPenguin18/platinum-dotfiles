#Run this once you have updated your system and run raspi-config

#Set a static IP address
sudo echo "interface eth0" >> /etc/dhcpcd.conf
sudo echo "static ip_address=192.168.0.30/24" >> /etc/dhcpcd.conf
sudo echo "static routers=192.168.0.1" >> /etc/dhcpcd.conf
sudo echo "static domain_name_servers=1.1.1.1" >> /etc/dhcpcd.conf

#Install all necessary things
sudo apt-get install rclone openvpn qbittorrent-nox git unzip jq
git pull https://github.com/EmperorPenguin18/MediaServer

#Setup rclone mount
sudo echo "user_allow_other" >> /etc/fuse.conf
sudo mv ./MediaServer/rclone.conf /mnt/rclone.conf
sudo mkdir /mnt/Cloud
sudo mv ./MediaServer/rclone.service /etc/systemd/system/rclone.service

#Setup mergerfs
wget 'https://github.com/trapexit/mergerfs/releases/download/2.29.0/mergerfs_2.29.0.debian-buster_armhf.deb'
sudo dpkg -i mergerfs_2.29.0.debian-buster_armhf.deb
rm mergerfs_2.29.0.debian-buster_armhf.deb
sudo mkdir /mnt/Local
sudo mkdir /mnt/Local/TV
sudo mkdir /mnt/Local/Movies
sudo mkdir /mnt/MergerFS
sudo mv ./MediaServer/mergerfs.service /etc/systemd/system/mergerfs.service

#Setup VPN
wget https://account.surfshark.com/api/v1/server/configurations
sudo unzip -o /etc/openvpn configurations
rm configurations
sudo sed -i 's/auth-user-pass/auth-user-pass pass.txt/g' /etc/openvpn/ca-tor.prod.surfshark.com_udp.ovpn
sudo mv ./MediaServer/pass.txt /etc/openvpn/pass.txt
sudo mv ./MediaServer/openvpn.service /etc/systemd/system/openvpn.service

#Prevent IP leaks
sudo echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
sudo echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
sudo echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf
sudo echo "net.ipv6.conf.eth0.disable_ipv6=1" >> /etc/sysctl.conf
sudo echo "nameserver 1.1.1.1" > /etc/resolv.conf
sudo mv ./MediaServer/dnsleaktest.sh ./dnsleaktest.sh

#Setup torrent client
sudo mkdir /mnt/Downloads
sudo mv ./MediaServer/qbittorrent.service /etc/systemd/system/qbittorrent.service

#Install Jackett
wget 'https://github.com/Jackett/Jackett/releases/download/v0.16.916/Jackett.Binaries.LinuxARM32.tar.gz'
tar -xvzf Jackett.Binaries.LinuxARM32.tar.gz
rm Jackett.Binaries.LinuxARM32.tar.gz
sudo ./Jackett/install_service_systemd.sh

#Install Sonarr
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493
echo "deb http://apt.sonarr.tv/ master main" | sudo tee /etc/apt/sources.list.d/sonarr.list
sudo apt update
sudo apt install nzbdrone
sudo mv ./MediaServer/sonarr.service /etc/systemd/system/sonarr.service

#Install Radarr
curl -L -O $( curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4 )
tar -xvzf Radarr.develop.*.linux.tar.gz
mv Radarr /opt
rm Radarr.develop.*.linux.tar.gz
sudo mv ./MediaServer/radarr.service /etc/systemd/system/radarr.service

#Setup nightly uploads
sudo echo "0 2 * * * root /usr/bin/timeout -k 5 6h /usr/bin/rclone move -P /mnt/Local encrypted: --exclude-from *partial~ --delete-empty-src-dirs --min-age 1d /etc/cron.daily" > /etc/crontab

#Cleanup
sudo mv ./MediaServer/setup.sh ./setup.sh
sudo rm -r MediaServer
sudo systemctl daemon-reload
sudo systemctl enable rclone
sudo systemctl enable mergerfs
sudo systemctl enable --now openvpn
sudo systemctl enable qbittorrent
sudo systemctl enable sonarr
suod systemctl enable radarr
./dnsleaktest.sh
sleep 5
sudo reboot
