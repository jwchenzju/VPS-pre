#请注意这个配置RC4-CMD5加密已被识别，故只能应用于纯IPV6端口即39000-39099，切记！
#mkjason() 
    mkdir /etc/shadowsocks-r
    cat > /etc/shadowsocks-r/config.json <<'EOF'
{
    "server":"",
    "server_ipv6":"::",
    "local_address":"127.0.0.1",
    "local_port":1080,
    "port_password":{
    "39093":"o0vnvH$t^IvUh%L!",
    "39039":"o0vnvH$t^IvUh%L!"
    },
    "timeout":120,
    "method":"rc4-md5",
    "protocol":"origin",
    "protocol_param":"65500",
    "obfs":"plain",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":true,
    "fast_open":false,
    "workers":1
}


EOF
#docker-ssr
 docker run -d --net host --restart always \
           --log-driver local \
           --name ssr \
           -v /etc/shadowsocks-r:/etc/shadowsocks-r \
           teddysun/shadowsocks-r
