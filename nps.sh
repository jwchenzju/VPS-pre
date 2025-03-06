#nps服务器配置
docker run --restart always -d --net=host \
    -v /etc/nps/conf:/conf \
    --log-driver local \
    --name nps \
    yisier1/nps:v0.26.22
