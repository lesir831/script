#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 检查root权限
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误：该脚本必须以root权限运行。请使用sudo或切换root用户。${NC}"
    exit 1
fi

# 交互式选择源
echo -e "${YELLOW}请选择Docker源：${NC}"
echo "1) 国内源（清华镜像）"
echo "2) 官方源"
read -p "请输入数字 (1/2): " source_choice

case $source_choice in
    1)
        MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian"
        ;;
    2)
        MIRROR_URL="https://download.docker.com/linux/debian"
        ;;
    *)
        echo -e "${RED}错误：无效的选择，请输入1或2。${NC}"
        exit 1
        ;;
esac

# 安装依赖
echo -e "${YELLOW}[1/6] 正在更新系统并安装依赖...${NC}"
if ! apt update && apt upgrade -y; then
    echo -e "${RED}错误：系统更新失败。${NC}"
    exit 1
fi

if ! apt install -y curl vim wget gnupg dpkg apt-transport-https lsb-release ca-certificates; then
    echo -e "${RED}错误：依赖包安装失败。${NC}"
    exit 1
fi

# 添加GPG密钥
echo -e "${YELLOW}[2/6] 添加Docker GPG密钥...${NC}"
if ! curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-ce.gpg; then
    echo -e "${RED}错误：GPG密钥下载失败。${NC}"
    exit 1
fi

# 添加APT源
echo -e "${YELLOW}[3/6] 配置Docker APT源...${NC}"
DOCKER_LIST="/etc/apt/sources.list.d/docker.list"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-ce.gpg] ${MIRROR_URL} $(lsb_release -sc) stable" | tee $DOCKER_LIST >/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}错误：APT源配置失败。${NC}"
    exit 1
fi

# 安装Docker
echo -e "${YELLOW}[4/6] 安装Docker引擎...${NC}"
if ! apt update; then
    echo -e "${RED}错误：APT源更新失败。${NC}"
    exit 1
fi

if ! apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin; then
    echo -e "${RED}错误：Docker安装失败。${NC}"
    exit 1
fi

# 验证安装
echo -e "${YELLOW}[5/6] 验证安装结果...${NC}"
if ! command -v docker &>/dev/null; then
    echo -e "${RED}错误：Docker未正确安装。${NC}"
    exit 1
fi

if ! docker compose version &>/dev/null; then
    echo -e "${RED}错误：Docker Compose插件未正确安装。${NC}"
    exit 1
fi

# 启动服务
echo -e "${YELLOW}[6/6] 启动Docker服务...${NC}"
systemctl enable --now docker >/dev/null 2>&1

# 显示成功信息
echo -e "\n${GREEN}Docker 已成功安装！${NC}"
echo -e "${BLUE}Docker版本：$(docker --version | cut -d ',' -f 1)${NC}"
echo -e "${BLUE}Docker Compose版本：$(docker compose version | cut -d ' ' -f 4)${NC}"
echo -e "\n${YELLOW}提示：运行 ${BLUE}docker run hello-world ${YELLOW}测试基本功能${NC}"
