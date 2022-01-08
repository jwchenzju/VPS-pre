echo "bbr part"
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
chmod +x bbr.sh
./bbr.sh

echo "ssr part"
wget --no-check-certificate -O ssr.sh https://raw.githubusercontent.com/jwchenzju/ssr-centos8/master/ssr.sh
chmod +x ssr.sh
./ssr.sh 2>&1 | tee ssr.log

echo "vps config part"
wget --no-check-certificate -O vpspre.sh https://raw.githubusercontent.com/jwchenzju/VPS-pre/main/vpspre.sh
chmod +x vpspre.sh
./vpspre.sh 2>&1 | tee vpspre.log
