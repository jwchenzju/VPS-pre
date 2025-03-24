#!/bin/bash
# VPS预安装环境，用DOCKER安装和配置好SS+v2rayplugin
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

#配置防火墙，开启80，并转发39100-40000端口到SS，实现多端口,同时开启高位端口UDP以实现FULLCONE;同时增大连接数以防止多用户时连接不足
cfgfirewall() {
    systemctl start firewalld
    firewall-cmd --permanent --add-port=22/tcp
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --permanent --add-port=80/udp
    firewall-cmd --permanent --add-port=39000-39030/tcp
    firewall-cmd --permanent --add-port=39080-39090/tcp
    firewall-cmd --permanent --add-port=39100-40000/tcp
    firewall-cmd --permanent --add-port=1024-65535/udp
    #39000-39099只开通IPV6端口，用于IPV6梯子
    firewall-cmd --permanent --add-rich-rule='rule family='ipv6' port protocol='tcp' port='39000-39099' accept'
    firewall-cmd --permanent --add-forward-port=port=39100-40000:proto=tcp:toport=81
    firewall-cmd --permanent --add-forward-port=port=39100-40000:proto=udp:toport=81
    firewall-cmd --permanent --add-rich-rule='rule family='ipv6' forward-port port='39100-40000' to-port='81' protocol='tcp''
    firewall-cmd --permanent --add-rich-rule='rule family='ipv6' forward-port port='39100-40000' to-port='81' protocol='udp''
    firewall-cmd --reload
    systemctl enable firewalld
     cat > /etc/security/limits.d/max.conf <<'EOF'
* soft nofile 131072
* hard nofile 131072
* soft nproc 131072
* hard nproc 131072
* soft core unlimited
* hard core unlimited
* soft memlock 50000000
* hard memlock 50000000
EOF
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
EOF

    echo "jail.local cfg finished"
}

#SS+V2rayplugin配置，带IPV6
mkjson() {
    mkdir /etc/shadowsocks-libev
    cat > /etc/shadowsocks-libev/config.json <<'EOF'
{
    "server":["[::0]", "0.0.0.0"],
    "server_port":81,
    "password":"BJ8E8o!A5rT&V!meig7ZeA^Ji^hL7%nR",
    "method":"aes-256-gcm",
    "fast_open":false,
    "mode":"tcp_and_udp",
    "plugin":"v2ray-plugin",
    "plugin_opts":"server",
    "ipv6_first": true
}
EOF
    echo "SS jason in /etc/shadowsocks-libev/config.json finished"

}


#减缓DDOS攻击，网上查来的，不一定有用
cfgddos() {
    touch /etc/sysctl.d/ddos.conf
    echo "
# TCP SYN Flood Protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_max_syn_backlog = 262144
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 262144
#增加UDP缓冲，防止缓冲不足，IPV6DNS更新错误
sysctl -w net.core.rmem_max=7500000
sysctl -w net.core.wmem_max=7500000
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

installss(){
    yum -y erase podman buildah
    yum -y remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
    yum install -y yum-utils
    yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    yum -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl start docker
    systemctl enable docker
    docker run -d --net host --restart always \
           --log-driver local \
           --name ss \
           -v /etc/shadowsocks-libev:/etc/shadowsocks-libev \
           teddysun/shadowsocks-libev
}


install() {
    installbbr
    cfgfirewall
    installfail2ban
    cfgjaillocal
    mkjson
    cfgddos
    enkey
    installss
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
