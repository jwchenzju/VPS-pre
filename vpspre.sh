#!/bin/bash
# VPS预安装环境，为SSR安装配置好文件
# Author: 

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'


cfgfirewall() {
    systemctl start firewalld
    firewall-cmd --permanent --add-port=22/tcp
    firewall-cmd --permanent --add-port=20059/tcp
    firewall-cmd --permanent --add-port=20059/udp
    firewall-cmd --permanent --add-port=443/tcp
    firewall-cmd --permanent --add-port=443/udp
    firewall-cmd --permanent --add-port=39000-40000/tcp
    firewall-cmd --permanent --add-port=39000-40000/udp
    firewall-cmd --permanent --add-forward-port=port=39100-40000:proto=tcp:toport=20059
    firewall-cmd --permanent --add-forward-port=port=39100-40000:proto=udp:toport=20059
    firewall-cmd --reload
    systemctl enable firewalld
    echo "firewalld configuration finished"
}

installfail2ban() {
    yum -y install epel-release
    yum -y install fail2ban
    systemctl daemon-reload
    systemctl stop fail2ban
    systemctl enable fail2ban
    echo "fail2ban installation finished"
}

cfgssr2ban() {
    cat > /etc/fail2ban/filter.d/shadowsocks.conf <<'EOF'
[INCLUDES]
before = common.conf
[Definition]
_daemon = shadowsocks
failregex = ^\s+ERROR\s\s\s\s+tcprelay.py:1097 can not parse header when handling connection from <HOST>:\d+$
ignoreregex =
EOF
    echo "ssr2ban cfg finished"
}

cfgjaillocal() {
    cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
sshd_log= /var/log/secure
[sshd]
enabled=true
bantime  = 3600
[shadowsocks]
enabled = true
filter = shadowsocks
port = 443,20059,39000-40000
logpath = /var/log/shadowsocksr.log
maxretry = 1
bantime  = 3600
EOF

    echo "jail.local cfg finished"
}

mkjason() {
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
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
    echo "SSR jason in /etc/shadowsocks-r/config.json finished"

}

enlargesoft() {
    echo "* soft nofile 65535" >>/etc/security/limits.conf
    echo "* hard nofile 65535" >>/etc/security/limits.conf
    echo "soft/hard nofile enlarged to 65535"
}

cfglogrote() {
    cat > /etc/logrotate.d/shadowsocksr <<'EOF'
/var/log/shadowsocksr.log {
weekly
size 10M
rotate 5
dateext
copytruncate
missingok
nocompress
}
EOF
    echo "logrotate for shadowsocks finished"
}

cfgdns() {
    echo "
DNS1=8.8.8.8
DNS2=8.8.4.4
DNS3=1.1.1.1" >> /etc/sysconfig/network-scripts/ifcfg-eth0
    echo "DNS changed to google and cloudflare"

}

cfgddos() {
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
" >> /etc/sysctl.conf
    echo "DDOS cfg finished"
}

install() {
    cfgfirewall
    installfail2ban
    cfgssr2ban
    cfgjaillocal
    mkjason
    enlargesoft
    cfglogrote
    cfgdns
    cfgddos
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
