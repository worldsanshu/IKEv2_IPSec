#!/bin/bash
set -e

WAN_IF="ens5"
VPN_POOL="10.10.10.0/24"
PSK_KEY="CSg7qTLKOSutn4GY3eEWNXEZrxlYMGAf"
/Users/ahfei/Downloads/ipsec_deploy_package (1)/uninstall_ipsec.sh
echo "[1/6] 安装依赖..."
apt update && apt install -y build-essential libnss3-dev libnspr4-dev pkg-config     libpam0g-dev libcap-ng-dev libcap-ng-utils libselinux1-dev     flex bison gcc make libcurl4-nss-dev libnss3-tools libevent-dev     libsystemd-dev iptables iproute2 wget net-tools iptables-persistent

echo "[2/6] 下载并安装 Libreswan..."
cd /usr/local/src
wget -q https://download.libreswan.org/libreswan-5.3.tar.gz
tar xvf libreswan-5.3.tar.gz
cd libreswan-5.3
make programs && make install

echo "[3/6] 配置 ipsec..."
cat > /etc/ipsec.conf <<EOF
config setup
    uniqueids=no

conn ikev2-psk
    auto=add
    keyexchange=ikev2
    ike=aes256-sha2_256;modp2048
    esp=aes256-sha2_256

    left=%defaultroute
    leftid=@server
    leftsubnet=0.0.0.0/0
    authby=secret

    right=%any
    rightid=%any
    rightaddresspool=10.10.10.10-10.10.10.50
    modecfgdns="8.8.8.8 1.1.1.1"
EOF

cat > /etc/ipsec.secrets <<EOF
@server  %any  : PSK "$PSK_KEY"
EOF

echo "[4/6] 开启内核转发..."
sed -i 's/^#\?net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

echo "[5/6] 配置防火墙..."
iptables -t nat -A POSTROUTING -s $VPN_POOL -o $WAN_IF -j MASQUERADE
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s $VPN_POOL -j ACCEPT
netfilter-persistent save

echo "[6/6] 配置 systemd..."
cat > /etc/systemd/system/ipsec.service <<EOF
[Unit]
Description=Libreswan IKE (pluto) IPsec service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/libexec/ipsec/pluto --config /etc/ipsec.conf --stderrlog --nofork
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RuntimeDirectory=pluto
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now ipsec

echo "✅ 部署完成！查看日志： journalctl -u ipsec -f"
echo "🔑 PSK 密钥为: $PSK_KEY"

journalctl -u ipsec -f
