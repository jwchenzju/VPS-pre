#1KEYDOCKER安装后，可安装网盘
firewall-cmd --permanent --add-port=8888/tcp
mkdir -p /var/nextcloud
podman pull docker.io/nextcloud
podman create -p 8888:80 --log-driver k8s-file \
-v /var/nextcloud:/var/www/html \
--log-opt path=/var/log/nextcloud.log \
--log-opt max-size=50m \
--name nextcloud \
nextcloud

#添加为自动运行
podman generate systemd --restart-policy always -t 1 -n -f nextcloud
mv container-nextcloud.service /etc/systemd/system/
restorecon -R /etc/systemd/system/container-nextcloud.service
systemctl daemon-reload
systemctl enable container-nextcloud.service
