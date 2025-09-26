# Libreswan IKEv2 VPN 部署与卸载文档

## 部署步骤
1. 运行部署脚本：
   ```bash
   chmod +x deploy_ipsec.sh
   sudo ./deploy_ipsec.sh
   ```
2. 部署完成后，可用以下命令查看日志：
   ```bash
   journalctl -u ipsec -f
   ```

## 卸载步骤
1. 运行卸载脚本：
   ```bash
   chmod +x uninstall_ipsec.sh
   sudo ./uninstall_ipsec.sh
   ```
2. 脚本会停止服务、删除 systemd 配置、清理 iptables 规则、删除相关配置文件。
