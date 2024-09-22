#!/bin/sh

#Check if script has root privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi
ROOTNAME=$(basename $(awk '$1 ~ /^\/dev\// && $2 == "/" { print $1 }' /proc/self/mounts))
USER=$(ls /home)
mkdir -p /mnt/$ROOTNAME/configs
mkdir -p /etc/fstab.d
mkdir -p /media

#Install packages
apt-get install -y rclone mergerfs wireguard inotify-tools nfs-kernel-server docker.io resolvconf curl >/dev/null || exit 1

#Setup disks
ln -sf /mnt/$ROOTNAME/configs/external.fstab /etc/fstab.d/external.fstab && \
mount -a -T /etc/fstab.d/external.fstab || \
exit 1

#Setup VPN
ln -sf /media/configs/wg0.conf /etc/wireguard/wg0.conf && \
sed -i 's/PersistentKeepalive = 0/PersistentKeepalive = 25/g' /etc/wireguard/wg0.conf && \
[ ! -z "$(grep '1.1.1.1' /etc/resolv.conf)" ] && \
systemctl enable --now wg-quick@wg0 || \
exit 1

#Setup nightly uploads
echo "0 0 * * * root /media/configs/backup.sh" > /etc/crontab || exit 1

#Install qbittorrent
docker pull qbittorrentofficial/qbittorrent-nox:latest && \
export \
  QBT_EULA=accept \
  QBT_VERSION=latest \
  QBT_WEBUI_PORT=8080 \
  QBT_CONFIG_PATH="/mnt/$ROOTNAME/configs/qbittorrent" && \
docker run \
  -d \
  --restart always \
  -t \
  --name qbittorrent-nox \
  --read-only \
  --stop-timeout 1800 \
  --tmpfs /tmp \
  -e QBT_EULA \
  -e QBT_WEBUI_PORT \
  -p "$QBT_WEBUI_PORT":"$QBT_WEBUI_PORT"/tcp \
  -p 6881:6881/tcp \
  -p 6881:6881/udp \
  -v "$QBT_CONFIG_PATH":/config \
  -v /media:/media \
  qbittorrentofficial/qbittorrent-nox:${QBT_VERSION} || \
exit 1

#Install jackett
docker pull lscr.io/linuxserver/jackett:latest && \
docker run -d \
  --name=jackett \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e AUTO_UPDATE=true `#optional` \
  -e RUN_OPTS= `#optional` \
  -p 9117:9117 \
  -v /mnt/$ROOTNAME/configs/jackett:/config \
  -v /dev/null:/downloads \
  --restart always \
  lscr.io/linuxserver/jackett:latest || \
exit 1

#Install sonarr
docker pull ghcr.io/hotio/sonarr:latest && \
docker run -d \
  --restart always \
  --name sonarr \
  -p 8989:8989 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Etc/UTC" \
  -v /mnt/$ROOTNAME/configs/sonarr:/config \
  -v /media:/media \
  ghcr.io/hotio/sonarr || \
exit 1

#Install radarr
docker pull ghcr.io/hotio/radarr:latest && \
docker run -d \
  --restart always \
  --name radarr \
  -p 7878:7878 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Etc/UTC" \
  -v /mnt/$ROOTNAME/configs/radarr:/config \
  -v /media:/media \
  ghcr.io/hotio/radarr || \
exit 1

#Install lidarr
docker pull lscr.io/linuxserver/lidarr:latest && \
mkdir -p /media/configs/custom-services.d /media/configs/custom-cont-init.d && \
curl -s https://raw.githubusercontent.com/RandomNinjaAtk/arr-scripts/main/lidarr/scripts_init.bash > /media/configs/custom-cont-init.d/scripts_init.bash && \
docker run -d \
  --restart always \
  --name lidarr \
  -p 8686:8686 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Etc/UTC" \
  -v /mnt/$ROOTNAME/configs/lidarr:/config \
  -v /media:/media \
  -v /media/configs/custom-services.d:/custom-services.d \
  -v /media/configs/custom-cont-init.d:/custom-cont-init.d \
  lscr.io/linuxserver/lidarr || \
exit 1

#Install jellyfin
docker pull jellyfin/jellyfin:latest && \
docker run \
  -d \
  --restart always \
  --name jellyfin \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -v /mnt/$ROOTNAME/configs/jellyfin:/config \
  -v /media/cache:/cache \
  -v /media:/media \
  -p 8096:8096 \
  jellyfin/jellyfin || \
exit 1

#Install jellyseerr
docker pull fallenbagel/jellyseerr:latest && \
docker run -d \
  --name jellyseerr \
  -e LOG_LEVEL=debug \
  -e TZ=Asia/Tashkent \
  -p 5055:5055 \
  -v /mnt/sda1/configs/jellyseerr:/app/config \
  --restart always \
  -e PUID=1000 \
  -e PGID=1000 \
  fallenbagel/jellyseerr:latest || \
exit 1

#Fix permissions
chown $USER:$USER -R /media || exit 1
