#1KEYDOCKER安装后，可安装网盘
mkdir -p /var/www/html
podman pull nextcloud
podman create -p 443:80 --log-driver k8s-file \
--log-opt path=/var/log/nextcloud.log \
--log-opt max-size=50m \
--name nextcloud \
-v /var/www/html:/var/www/html \
nextcloud

#添加为自动运行
podman generate systemd --restart-policy always -t 1 -n -f nextcloud
mv container-nextcloud.service /etc/systemd/system/
restorecon -R /etc/systemd/system/container-nextcloud.service
systemctl daemon-reload
systemctl enable container-nextcloud.service
