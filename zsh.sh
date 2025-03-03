#!/bin/bash
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --------------------- 包管理器检测 ---------------------
PM=""
SUDO="sudo"
[ "$(id -u)" -eq 0 ] && SUDO=""  # root用户不需要sudo

# 检测包管理器优先级: apt-get -> dnf -> yum
if command -v apt-get &>/dev/null; then
    PM="apt-get"
elif command -v dnf &>/dev/null; then
    PM="dnf"
elif command -v yum &>/dev/null; then
    PM="yum"
else
    echo -e "${RED}错误：未找到支持的包管理器 (apt-get/dnf/yum)${NC}"
    exit 1
fi

# --------------------- 依赖检测函数 ---------------------
is_installed() {
    local pkg="$1"
    case $PM in
        apt-get)
            dpkg -s "$pkg" &>/dev/null
            ;;
        dnf|yum)
            rpm -q "$pkg" &>/dev/null
            ;;
        *)
            echo -e "${RED}错误：不支持的包管理器${NC}"
            return 1
            ;;
    esac
}

# --------------------- 基础依赖安装 ---------------------
echo -e "${YELLOW}检查系统依赖...${NC}"
for pkg in zsh curl git; do
    if is_installed "$pkg"; then
        echo -e "${GREEN}✓ ${pkg} 已安装${NC}"
    else
        echo -e "${YELLOW}正在安装 ${pkg}...${NC}"
        $SUDO $PM install -y "$pkg"
    fi
done

# --------------------- autojump智能安装 ---------------------
install_autojump() {
    local pkg_name="autojump"
  
    # 特殊处理RHEL系
    if [[ "$PM" == "dnf" || "$PM" == "yum" ]]; then
        if ! is_installed "epel-release"; then
            echo -e "${YELLOW}安装EPEL源...${NC}"
            $SUDO $PM install -y epel-release
        fi
        pkg_name="autojump-zsh"
    fi

    if is_installed "$pkg_name"; then
        echo -e "${GREEN}✓ ${pkg_name} 已安装${NC}"
    else
        echo -e "${YELLOW}正在安装 ${pkg_name}...${NC}"
        $SUDO $PM install -y "$pkg_name"
    fi
}
install_autojump

# --------------------- oh-my-zsh安装 ---------------------
OHMYZSH_DIR="$HOME/.oh-my-zsh"
if [ -d "$OHMYZSH_DIR" ]; then
    echo -e "${GREEN}✓ oh-my-zsh 已安装${NC}"
else
    echo -e "${YELLOW}正在安装 oh-my-zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --------------------- 插件安装 ---------------------
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
function clone_plugin() {
    local repo="$1"
    local name=$(basename "$repo" .git)
  
    if [ ! -d "${HOME}/.oh-my-zsh/custom/plugins/${name}" ]; then
        echo -e "${YELLOW}安装插件: ${name}...${NC}"
        git clone --depth=1 "$repo" "${HOME}/.oh-my-zsh/custom/plugins/${name}"
    else
        echo -e "${GREEN}✓ ${name} 已安装${NC}"
    fi
}

clone_plugin "https://github.com/zsh-users/zsh-autosuggestions"
clone_plugin "https://github.com/zdharma-continuum/fast-syntax-highlighting"

# --------------------- 配置文件修改 ---------------------
config_zshrc() {
    local config_file="$HOME/.zshrc"
  
    # 插件管理
    local plugins=(git autojump zsh-autosuggestions fast-syntax-highlighting)
    if grep -q "^plugins=" "$config_file"; then
        existing_plugins=$(grep "^plugins=" "$config_file" | sed -E 's/plugins=\((.*)\)/\1/')
        all_plugins=($(echo "$existing_plugins ${plugins[*]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        sed -i.bak "s/^plugins=.*/plugins=(${all_plugins[*]})/" "$config_file"
    else
        echo "plugins=(${plugins[*]})" >> "$config_file"
    fi

    # 智能添加配置
    function add_config {
        local pattern="$1"
        local line="$2"
        if ! grep -q "$pattern" "$config_file"; then
            echo "$line" >> "$config_file"
            echo -e "${YELLOW}添加配置: ${line}${NC}"
        else
            echo -e "${GREEN}✓ 配置已存在: ${pattern}${NC}"
        fi
    }

    add_config "FAST_HIGHLIGHT" "source \$ZSH_CUSTOM/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
    add_config "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'"
}
config_zshrc

# --------------------- 设置zsh为默认shell ---------------------
current_shell=$(getent passwd $USER | cut -d: -f7)
zsh_path=$(which zsh)

if [ "$current_shell" != "$zsh_path" ]; then
    echo -e "${YELLOW}设置zsh为默认shell...${NC}"
    
    # 针对root用户的特殊处理
    if [ "$(id -u)" -eq 0 ]; then
        # 直接修改/etc/passwd文件
        sed -i "s|^root:.*$|root:x:0:0:root:/root:$zsh_path|" /etc/passwd
        echo -e "${GREEN}✓ root用户的默认shell已更改为zsh${NC}"
    else
        # 普通用户使用chsh命令
        $SUDO chsh -s "$zsh_path" "$USER"
        echo -e "${GREEN}✓ zsh已设置为默认shell${NC}"
    fi
else
    echo -e "${GREEN}✓ zsh已经是默认shell${NC}"
fi

# --------------------- 完成提示 ---------------------
echo -e "\n${GREEN}✅ 安装完成！${NC}"
echo -e "所有配置已设置好，将在下次登录时生效。"
echo -e "如需立即切换到zsh，请运行:\n"
echo -e "${YELLOW}exec zsh${NC}"

# 自动切换到zsh并应用配置
echo -e "${GREEN}切换到zsh并应用新配置...${NC}"
exec zsh -l
