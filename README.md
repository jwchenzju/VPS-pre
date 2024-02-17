# VPS-pre
实际部署于almalinux系统，自动DOCKER安装ss-libev，并配置好相关环境，包括：
安装BBR；
防火墙设置，转发端口模拟多端口，开启必要端口以实现游戏环境的FULLCONE；
安装fail2ban并配置规则以保护SSH；
配置SS-libev的JSON文件；
配置DDOS减缓策略；
应用个人证书（此项在使用时请务必更改！）；
安装DOCKER并启动SS-libev+v2ray-plugin;
此脚本仅适用于个人的VPS，他人使用时请确保已清楚内容和后果。

其它脚本为SSR的DOCKER安装；BT端口封禁；nextcloud的docker安装等。
脚本很粗糙，有些命令在不同系统可能有问题需要调试，仅供入门者使用。
