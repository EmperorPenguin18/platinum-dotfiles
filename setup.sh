#!/bin/sh

#Check if script has root privileges
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi
ROOTNAME=$(basename $(awk '$1 ~ /^\/dev\// && $2 == "/" { print $1 }' /proc/self/mounts))
mkdir -p /mnt/$ROOTNAME/configs
mkdir -p /etc/fstab.d
mkdir -p /media

#Install packages
apt-get install -y rclone mergerfs wireguard inotify-tools nfs-kernel-server docker.io >/dev/null || exit 1

#Setup disks
ln -sf /mnt/$ROOTNAME/configs/external.fstab /etc/fstab.d/external.fstab || exit 1

#Setup VPN
ln -sf /media/configs/wg0.conf /etc/wireguard/wg0.conf && \
systemctl enable wg-quick@wg0 || \
exit 1

#Setup nightly uploads
echo "0 0 * * * root /media/configs/backup.sh" > /etc/crontab || exit 1

#Install qbittorrent
docker pull qbittorrentofficial/qbittorrent-nox:latest && \
export \
  QBT_EULA=accept \
  QBT_VERSION=latest \
  QBT_WEBUI_PORT=8080 \
  QBT_CONFIG_PATH="/media/configs" \
  QBT_DOWNLOADS_PATH="/media/downloads" && \
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
  -v "$QBT_DOWNLOADS_PATH":/downloads \
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
  -v /media/configs:/config \
  -v /dev/null:/downloads \
  --restart unless-stopped \
  lscr.io/linuxserver/jackett:latest || \
exit 1

#Install sonarr
docker pull ghcr.io/hotio/sonarr:release && \
docker run -d \
  --restart always \
  --name sonarr \
  -p 8989:8989 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Etc/UTC" \
  -v /media/configs:/config \
  -v /media/data:/data \
  ghcr.io/hotio/sonarr || \
exit 1

#Install radarr
docker pull ghcr.io/hotio/radarr:release && \
docker run -d \
  --restart always \
  --name radarr \
  -p 7878:7878 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Etc/UTC" \
  -v /media/configs:/config \
  -v /media/data:/data \
  ghcr.io/hotio/radarr || \
exit 1

#Install lidarr
docker pull ghcr.io/hotio/lidarr:release && \
docker run -d \
  --restart always \
  --name lidarr \
  -p 8686:8686 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e TZ="Etc/UTC" \
  -v /media/configs:/config \
  -v /media/data:/data \
  ghcr.io/hotio/lidarr || \
exit 1

#Install jellyfin
docker pull jellyfin/jellyfin:latest && \
docker run \
  -d \
  --restart always \
  -v /media/configs:/config \
  -v /media/cache:/cache \
  -v /media:/media \
  --net=host \
  jellyfin/jellyfin || \
exit 1

#Install overseerr
docker pull sctx/overseerr && \
docker run -d \
  --name overseerr \
  -e LOG_LEVEL=debug \
  -e TZ=Asia/Tokyo \
  -e PORT=5055 `#optional` \
  -p 5055:5055 \
  -v /media/configs:/app/config \
  --restart unless-stopped \
  sctx/overseerr || \
exit 1
