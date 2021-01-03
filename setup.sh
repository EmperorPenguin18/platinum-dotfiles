#Run this once you have updated and configured your system

#Check if script has root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

#Set a static IP address
echo "interface eth0" >> /etc/dhcpcd.conf
echo "static ip_address=192.168.0.19/24" >> /etc/dhcpcd.conf
echo "static routers=192.168.0.1" >> /etc/dhcpcd.conf
echo "static domain_name_servers=1.1.1.1" >> /etc/dhcpcd.conf

#Install all necessary things
apt-get install -y rclone mergerfs openvpn qbittorrent-nox unzip apt-transport-https software-properties-common nginx inotify-tools

#Setup rclone mount
echo "user_allow_other" >> /etc/fuse.conf
mv ./rclone.conf /mnt/rclone.conf
mkdir /mnt/Cloud
mv ./rclone.service /etc/systemd/system/rclone.service

#Setup mergerfs
mkdir /mnt/Local
mkdir /mnt/Local/TV
mkdir /mnt/Local/Movies
mkdir /mnt/MergerFS
mv ./mergerfs.service /etc/systemd/system/mergerfs.service
echo "fs.inotify.max_user_watches=262144" >> /etc/sysctl.conf

#Setup VPN
unzip mullvad_openvpn_linux_ca_tor.zip
rm mullvad_openvpn_linux_ca_tor.zip
chmod +x ./mullvad_config_linux_ca_tor/update_resolv_conf
mv ./mullvad_config_linux_ca_tor/* /etc/openvpn/
chmod +x /etc/openvpn/update-resolv-conf
rmdir mullvad_config_linux_ca_tor
mv ./openvpn.service /etc/systemd/system/openvpn.service

#Setup torrent client
mkdir /mnt/Downloads
mkdir -p /.config/qBittorrent
mv qBittorrent.conf /.config/qBittorrent/qBittorrent.conf
mv ./qbittorrent.service /etc/systemd/system/qbittorrent.service

#Install Jackett
wget 'https://github.com/Jackett/Jackett/releases/download/v0.16.962/Jackett.Binaries.LinuxAMDx64.tar.gz'
tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz
rm Jackett.Binaries.LinuxAMDx64.tar.gz
mv Jackett ../Jackett
chown -R media:media ../Jackett
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
mv upload.sh ../upload.sh
chmod +x ../upload.sh
echo "0 0 * * * root /home/media/upload.sh" > /etc/crontab

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

#Setup nginx
mv jellyfin.conf /etc/nginx/conf.d/jellyfin.conf
mv ombi.conf /etc/nginx/conf.d/ombi.conf
rm /etc/nginx/nginx.conf
mv ./nginx.conf /etc/nginx/nginx.conf

#Cleanup
cd ../
mv ./MediaServer/setup.sh ./setup.sh
rm -r MediaServer
systemctl daemon-reload
systemctl enable rclone
systemctl enable mergerfs
systemctl enable openvpn
systemctl enable qbittorrent
systemctl enable sonarr
systemctl enable radarr
systemctl enable jellyfin
systemctl enable ombi
systemctl enable nginx
reboot

#https://www.youtube.com/watch?v=z8hizZRX5-4&ab_channel=SunKnudsen
#https://www.howtogeek.com/443156/the-best-ways-to-secure-your-ssh-server/
