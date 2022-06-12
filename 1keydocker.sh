#!/bin/bash
# VPS预安装环境，用DOCKER安装和配置好SSR
# Author: Delphi Chen

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

#安装BBR，因为新版本都是新内核，直接改配置文件即可
installbbr(){
    touch /etc/sysctl.d/bbr.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/bbr.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/bbr.conf
    echo "bbr configuration finished"
}

#配置防火墙，开启20058/20059，并转发39100-40000端口到SSRR，实现多端口
cfgfirewall() {
    systemctl start firewalld
    firewall-cmd --permanent --add-port=22/tcp
    firewall-cmd --permanent --add-port=20058-20059/tcp
    firewall-cmd --permanent --add-port=20058-20059/udp
    firewall-cmd --permanent --add-port=443/tcp
    firewall-cmd --permanent --add-port=443/udp
    firewall-cmd --permanent --add-port=39000-40000/tcp
    firewall-cmd --permanent --add-port=39000-40000/udp
    firewall-cmd --permanent --add-forward-port=port=39100-40000:proto=tcp:toport=20059
    firewall-cmd --permanent --add-forward-port=port=39100-40000:proto=udp:toport=20059
    firewall-cmd --permanent --add-rich-rule='rule family='ipv6' forward-port port='39100-40000' to-port='20059' protocol='tcp''
    firewall-cmd --permanent --add-rich-rule='rule family='ipv6' forward-port port='39100-40000' to-port='20059' protocol='udp''
    firewall-cmd --reload
    systemctl enable firewalld
    echo "firewalld configuration finished"
}

#FAIL2BAN用于保护SSHD
installfail2ban() {
    yum -y install epel-release
    yum -y install fail2ban
    systemctl daemon-reload
    systemctl enable fail2ban
    echo "fail2ban installation finished"
}

cfgjaillocal() {
    cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled=true
bantime  = 3600
EOF

    echo "jail.local cfg finished"
}

#SSRR配置，并转发错误至443的HTTPS网站，应配置网站并配备证书叉混淆防火墙的探测
mkjson() {
    mkdir /etc/shadowsocks-r
    cat > /etc/shadowsocks-r/config.json <<'EOF'
{
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "local_address":"127.0.0.1",
    "local_port":1080,
    "port_password":{
    "20058":"o0vnvH$t^IvUh%L!",
    "20059":"o0vnvH$t^IvUh%L!"
    },
    "timeout":120,
    "method":"none",
    "protocol":"auth_chain_d",
    "protocol_param":"65500",
    "obfs":"plain",
    "obfs_param":"",
    "redirect":"127.0.0.1:443",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
    echo "SSR jason in /etc/shadowsocks-r/config.json finished"

}

#这个其实在新的SYSTEMD已经没有意义了
enlargesoft() {
    touch /etc/security/limits.d/large.conf
    echo "* soft nofile 65535" >>/etc/security/limits.d/large.conf
    echo "* hard nofile 65535" >>/etc/security/limits.d/large.conf
    echo "soft/hard nofile enlarged to 65535"
}

cfglogrote() {
    yum -y install logrotate
    echo "logrotate installed"
}

#对PODMAN的日志进行滚动，不然时间长了会填满硬盘
rotepodman(){
#限制PODMAN日志不大于50M
touch /etc/containers/containers.conf
echo "[containers]" >>/etc/containers/containers.conf
echo "log_size_max=50000000" >>/etc/containers/containers.conf
#限制journal尺寸
mkdir /etc/systemd/journald.conf.d
touch /etc/systemd/journald.conf.d/limitsize.conf
echo "[Journal]" >>/etc/systemd/journald.conf.d/limitsize.conf
echo "SystemMaxUse=50M" >>/etc/systemd/journald.conf.d/limitsize.conf
echo "RuntimeMaxUse=50M" >>/etc/systemd/journald.conf.d/limitsize.conf
}

#减缓DDOS攻击，网上查来的，不一定有用
cfgddos() {
    touch /etc/sysctl.d/ddos.conf
    echo "
# TCP SYN Flood Protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_max_syn_backlog = 262144
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_keepalive_time = 1200
" >> /etc/sysctl.d/ddos.conf
    echo "DDOS cfg finished"
}

#此项不要用！这是我个人的证书！
enkey() {
    mkdir /root/.ssh
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3nySoKInWCHtdS5SVCKdJXVoclWGumaYx9sm5YQBpG ed25519-key-20220506" >>/root/.ssh/authorized_keys
    sed -i '/^PasswordAuthentication/s/^/#/g' /etc/ssh/sshd_config
    sed -i '/PasswordAuthentication/a\PasswordAuthentication no' /etc/ssh/sshd_config
}

installssr(){
    yum install -y podman podman-docker
    podman pull docker.io/teddysun/shadowsocks-r:latest
    podman create --net host --name ssr \
-v /etc/shadowsocks-r:/etc/shadowsocks-r \
teddysun/shadowsocks-r
}

#启用SSR的开机自动运行
autossr(){
    podman generate systemd --restart-policy always -t 1 -n -f ssr
    mv container-ssr.service /etc/systemd/system/
    restorecon -R /etc/systemd/system/container-ssr.service
    systemctl daemon-reload
    systemctl enable container-ssr.service
}

install() {
    installbbr
    cfgfirewall
    installfail2ban
    cfgjaillocal
    mkjson
    enlargesoft
    cfglogrote
    rotepodman
    cfgddos
    enkey
    installssr
    autossr
    echo "script finished"
}

menu() {
    echo -e "  ${GREEN}1.${PLAIN}  install VPS pre-environment"
    echo " Only for private use, do not try to use if you are not clear"
    echo -e "  ${GREEN}0.${PLAIN} 退出"
    echo 
    echo 

    read -p " 请选择操作/please select[0-1]：" answer
    case $answer in
        0)
            exit 0
            ;;
        1)
            install
            ;;
            
        *)
            echo -e "$RED 请选择正确的操作！${PLAIN}"
            exit 1
            ;;
    esac
}

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
    menu|install)
        ${action}
        ;;
    *)
        echo " 参数错误"
        echo " 用法: `basename $0` [menu|install]"
        ;;
esac
