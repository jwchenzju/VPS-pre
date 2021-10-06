# VPS-pre
安装SSR后的VPS配置
自动在安装SSR，配置好相关环境，包括：
防火墙设置，转发端口模拟多端口；
安装fail2ban
配置fail2ban规则以保护SSH和SSR
配置jail.local开启保护
配置SSR的JSON文件
修改SOFT和HARD的限值为最大
配置LOGROTATE自动整理日志
配置VPS的DNS为google和cloudflare
配置DDOS减缓策略

此脚本仅适用于个人的VPS，他人使用时请确保已清楚内容和后果。
