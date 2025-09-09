#!/bin/bash

# =================================================================
# 3x-ui Docker 一键部署脚本 (修正版)
# 适用于 Ubuntu 20.04 及以上版本
# 镜像地址: 57311/3x-ui
# =================================================================

# --- 配置参数 ---
# 你可以根据需要修改这些值
DOCKER_IMAGE="57311/3x-ui"
CONTAINER_NAME="3x-ui"                   # 容器名称
PANEL_PORT="10000"                       # 面板端口
VLESS_PORT="443"                         # 主要 VLESS 端口
PORT_RANGE="10001-59999"                 # 需要映射的额外端口范围 (给 Docker 使用)
UFW_PORT_RANGE="10001:59999"             # 需要开放的额外端口范围 (给 UFW 防火墙使用)

CONFIG_PATH="/root/3x-ui/config"         # 配置文件路径
DB_PATH="/root/3x-ui/db"                 # 数据库文件路径

# --- 脚本开始 ---

# 设置脚本在遇到错误时立即退出
set -e

# 1. 更新系统并安装必要的依赖
echo ">>> 正在更新系统并安装依赖..."
sudo apt-get update
# sudo apt-get upgrade -y  # 此行可选，如果服务器是全新的，可以运行以升级所有软件包，但可能耗时较长
sudo apt-get install -y ca-certificates curl gnupg

# 2. 安装 Docker
if ! command -v docker &> /dev/null
then
    echo ">>> Docker 未安装，正在开始安装..."
    # 添加 Docker 的官方 GPG 密钥
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # 设置 Docker 的 Apt 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新 Apt 包索引并安装 Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo ">>> Docker 安装完成！"
else
    echo ">>> Docker 已安装，跳过安装步骤。"
fi

# 3. 配置防火墙 (UFW)
echo ">>> 正在配置防火墙规则..."
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow ${PANEL_PORT}/tcp comment '3x-ui Panel'
sudo ufw allow ${VLESS_PORT}/tcp comment 'VLESS TCP'
sudo ufw allow ${VLESS_PORT}/udp comment 'VLESS UDP'
sudo ufw allow ${UFW_PORT_RANGE}/tcp comment 'Optional Port Range TCP'
sudo ufw allow ${UFW_PORT_RANGE}/udp comment 'Optional Port Range UDP'

# 强制启用 UFW，并自动回答 'y'
yes | sudo ufw enable
sudo ufw reload
echo ">>> 防火墙配置完成！"

# 4. 创建用于持久化存储的目录
echo ">>> 正在创建数据存储目录..."
sudo mkdir -p ${CONFIG_PATH}
sudo mkdir -p ${DB_PATH}
echo ">>> 数据目录创建于 ${CONFIG_PATH} 和 ${DB_PATH}"

# 5. 部署 Docker 容器
echo ">>> 正在拉取最新的镜像: ${DOCKER_IMAGE}..."
sudo docker pull ${DOCKER_IMAGE}

echo ">>> 正在停止并删除可能存在的旧容器..."
# 使用 || true 来防止在容器不存在时脚本出错退出
sudo docker stop ${CONTAINER_NAME} || true
sudo docker rm ${CONTAINER_NAME} || true

echo ">>> 正在启动新的 3x-ui 容器..."
sudo docker run -d \
    --name ${CONTAINER_NAME} \
    --restart=always \
    -v ${DB_PATH}:/etc/x-ui/ \
    -v ${CONFIG_PATH}:/etc/x-ui/config/ \
    -p ${PANEL_PORT}:${PANEL_PORT} \
    -p ${VLESS_PORT}:${VLESS_PORT}/tcp \
    -p ${VLESS_PORT}:${VLESS_PORT}/udp \
    -p ${PORT_RANGE}:${PORT_RANGE}/tcp \
    -p ${PORT_RANGE}:${PORT_RANGE}/udp \
    ${DOCKER_IMAGE}

# --- 脚本结束 ---
echo ""
echo "🎉 恭喜！3x-ui 部署完成！"
echo "--------------------------------------------------"
echo "你可以通过以下地址访问面板："
echo "URL: http://<你的服务器IP>:${PANEL_PORT}"
echo ""
echo "请记得首次登录后，在面板设置中修改用户名和密码。"
echo "--------------------------------------------------"