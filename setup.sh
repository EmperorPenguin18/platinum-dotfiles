#Check if script has root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
ROOTNAME=$(basename $(awk '$1 ~ /^\/dev\// && $2 == "/" { print $1 }' /proc/self/mounts))
mkdir -p /mnt/$ROOTNAME/configs
mkdir -p /media

#Install packages
apt-get install -y rclone mergerfs wireguard inotify-tools nfs-kernel-server docker

#Setup disks
ln -sf /mnt/$ROOTNAME/configs/external.fstab /etc/fstab.d/external.fstab

#Setup VPN
ln -sf /media/configs/wg0.conf /etc/wireguard/wg0.conf
systemctl enable wg-quick@wg0

#Setup nightly uploads
#echo "0 0 * * * root /home/media/upload.sh" > /etc/crontab

#Install containers
docker pull qbittorrentofficial/qbittorrent-nox
docker pull linuxserver/jackett
docker pull ghcr.io/hotio/sonarr:release
docker pull ghcr.io/hotio/radarr:release
docker pull ghcr.io/hotio/lidarr:release
docker pull jellyfin/jellyfin:latest
docker pull sctx/overseerr
