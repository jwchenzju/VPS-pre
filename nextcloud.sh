#1KEYDOCKER安装后，可安装网盘
docker run --restart=always -d -p 8888:80 \
    -v nextcloud:/var/www/html \
    --log-driver local \
    --log-opt max-size=10m \
    --log-opt max-file=5 \
    --name nextcloud \
    nextcloud
