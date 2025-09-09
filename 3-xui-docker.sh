#!/bin/bash

# ==============================================================================
# 3x-ui Docker 极简一键部署脚本 (适用于全新的 Ubuntu 服务器)
# ==============================================================================

# --- 配置区 ---
DOCKERHUB_USERNAME="57311"
HOST_PORT="10000"
CONTAINER_NAME="3x-ui"
# --- 配置结束 ---


# 1. 更新系统并安装 Docker
# 使用 && 连接，确保更新成功后再执行安装
apt-get update && apt-get install -y docker.io

# 2. 启动并设置 Docker 开机自启
# 确保服务器重启后 Docker 服务能自动运行
systemctl start docker
systemctl enable docker

# 3. 从 Docker Hub 拉取你的镜像
# ${DOCKERHUB_USERNAME} 会被替换成上面配置的 "57311"
docker pull "${DOCKERHUB_USERNAME}/3x-ui:latest"

# 4. 运行 Docker 容器
# 注意：如果服务器上已存在同名容器，此命令会执行失败。此脚本为极简版，不处理旧容器。
# -d 后台运行, --restart=always 自动重启, -v 数据持久化, -p 端口映射
docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart=always \
    -v /etc/x-ui/:/etc/x-ui/ \
    -v /var/lib/x-ui/:/var/lib/x-ui/ \
    -p "${HOST_PORT}:2053" \
    "${DOCKERHUB_USERNAME}/3x-ui:latest"

# 5. 配置服务器系统防火墙 (UFW)
# 允许 SSH 端口，防止断开连接
ufw allow ssh
# 允许我们设定的应用端口
ufw allow ${HOST_PORT}/tcp
# 使用 'echo "y" |' 来自动确认启用防火墙，避免脚本卡住
echo "y" | ufw enable

# 6. 脚本执行完毕，显示最终提示信息
echo "==================== 部署脚本执行完毕 ===================="
echo "请使用浏览器访问: http://$(curl -s ifconfig.me):${HOST_PORT}"
echo "默认用户名: admin / 默认密码: admin"
echo ""
echo "重要提醒：请务必登录您的【云服务商控制台】，在防火墙或安全组中，手动放行 TCP 端口 ${HOST_PORT}！"
echo "========================================================"