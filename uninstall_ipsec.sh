#!/bin/bash
set -e

WAN_IF="ens5"
VPN_POOL="10.10.10.0/24"

echo "[1/5] 停止并禁用服务..."
systemctl stop ipsec || true
systemctl disable ipsec || true

echo "[2/5] 删除 systemd 配置..."
rm -f /etc/systemd/system/ipsec.service
systemctl daemon-reload

echo "[3/5] 清理 iptables 规则..."
iptables -t nat -D POSTROUTING -s $VPN_POOL -o $WAN_IF -j MASQUERADE || true
iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT || true
iptables -D FORWARD -s $VPN_POOL -j ACCEPT || true
netfilter-persistent save || true

echo "[4/5] 删除配置文件..."
rm -f /etc/ipsec.conf /etc/ipsec.secrets

echo "[5/5] 清理源码目录..."
rm -rf /usr/local/src/libreswan-5.3*

echo "✅ 卸载清理完成"
