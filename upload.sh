/usr/bin/timeout -k 5 6h /usr/bin/rclone move --config /mnt/rclone.conf -P /mnt/Local encrypted: --exclude *partial~ --delete-empty-src-dirs --min-age 1d
