#Run this once you have updated your system and run raspi-config

sudo echo "interface eth0" >> /etc/dhcpcd.conf
sudo echo "static ip_address=192.168.0.30/24" >> /etc/dhcpcd.conf
sudo echo "static routers=192.168.0.1" >> /etc/dhcpcd.conf
sudo echo "static domain_name_servers=1.1.1.1" >> /etc/dhcpcd.conf
sudo apt-get install rclone mergerfs openvpn qbittorrent-nox git unzip jq
git pull https://github.com/EmperorPenguin18/MediaServer
sudo mv ./MediaServer/rclone.conf /mnt/rclone.conf
sudo mkdir /mnt/Cloud
sudo mv ./MediaServer/rclone.service /etc/systemd/system/rclone.service
sudo mkdir /mnt/MergerTV
sudo mkdir /mnt/MergerMovies
sudo mv ./MediaServer/mergerfst.service /etc/systemd/system/mergerfst.service
sudo mv ./MediaServer/mergerfsm.service /etc/systemd/system/mergerfsm.service
wget https://account.surfshark.com/api/v1/server/configurations
sudo unzip -o /etc/openvpn configurations
rm configurations
sudo sed -i 's/auth-user-pass/auth-user-pass pass.txt/g' /etc/openvpn/ca-tor.prod.surfshark.com_udp.ovpn
sudo mv ./MediaServer/pass.txt /etc/openvpn/pass.txt
sudo mv ./MediaServer/openvpn.service /etc/systemd/system/openvpn.service
sudo echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
sudo echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
sudo echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf
sudo echo "net.ipv6.conf.eth0.disable_ipv6=1" >> /etc/sysctl.conf
sudo echo "nameserver 1.1.1.1" > /etc/resolv.conf
sudo mv ./MediaServer/dnsleaktest.sh ./dnsleaktest.sh
sudo mkdir /mnt/Downloads/TV
sudo mkdir /mnt/Downloads/Movies
sudo mv ./MediaServer/qbittorrent.service /etc/systemd/system/qbittorrent.service
wget 'https://github.com/Jackett/Jackett/releases/download/v0.16.916/Jackett.Binaries.LinuxARM32.tar.gz'
tar -xvzf Jackett.Binaries.LinuxARM32.tar.gz
rm Jackett.Binaries.LinuxARM32.tar.gz
sudo ./Jackett/install_service_systemd.sh
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493
echo "deb http://apt.sonarr.tv/ master main" | sudo tee /etc/apt/sources.list.d/sonarr.list
sudo apt update
sudo apt install nzbdrone
sudo mv ./MediaServer/sonarr.service /etc/systemd/system/sonarr.service
curl -L -O $( curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4 )
tar -xvzf Radarr.develop.*.linux.tar.gz
mv Radarr /opt
rm Radarr.develop.*.linux.tar.gz
sudo mv ./MediaServer/radarr.service /etc/systemd/system/radarr.service
sudo systemctl daemon-reload
sudo systemctl enable rclone
sudo systemctl enable mergerfst
sudo systemctl enable mergerfsm
sudo systemctl enable --now openvpn
sudo systemctl enable qbittorrent
sudo systemctl enable sonarr
suod systemctl enable radarr
./dnsleaktest.sh
sudo reboot
