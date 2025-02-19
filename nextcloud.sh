#1KEYDOCKER安装后，可安装网盘
#nextcloud大版本升级不能跳级，故此处约定版本号
docker run --restart always -d -p 8888:80 \
    -v /nextcloud:/var/www/html \
    --log-driver local \
    --env PHP_MEMORY_LIMIT=1024M \
    --env PHP_UPLOAD_LIMIT=1024M \
    --name nextcloud \
    nextcloud:30.0.5
