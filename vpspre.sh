#!/bin/bash
# VPS安装环境，为SSR安装配置好文件
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
    systemctl enable firewalld
}

installfail2ban() {
    yum -y install epel-release
    yum install fail2ban
}

cfgssr2ban() {
    cat > /etc/fail2ban/filter.d/shadowsocks.conf << -EOF
    [INCLUDES]
    before = common.conf
    [Definition]
    _daemon = shadowsocks
    failregex = ^\s+ERROR\s\s\s\s+tcprelay.py:1097 can not parse header when handling connection from <HOST>:\d+$
    ignoreregex =
    EOF
}

cfgjaillocal() {
    cat > /etc/fail2ban/jail.local << -EOF
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

    systemctl enable fail2ban
}

mkjason() {
    mkdir /etc/shadowsocks-r
    cat > /etc/shadowsocks-r/config.json << -EOF
    {
        "server":"0.0.0.0",
        "server_ipv6":"::",
        "local_address":"127.0.0.1",
        "local_port":1080,
        "port_password":{
        "443":"o0vnvH$t^IvUh%L!",
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

}

enlargesoft() {
    echo "* soft nofile 65535" >>/etc/security/limits.conf
    echo "* hard nofile 65535" >>/etc/security/limits.conf

}

cfglogrote() {
    cat > /etc/logrotate.d/shadowsocksr << -EOF
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
}

cfgdns() {
    echo "
    DNS1=8.8.8.8
    DNS2=8.8.4.4
    DNS3=1.1.1.1" >> /etc/sysconfig/network-scripts/ifcfg-eth0

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

action=install
