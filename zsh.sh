#!/bin/bash

# 更新包列表并安装zsh
echo "安装 zsh..."
sudo apt update
sudo apt install -y zsh

# 安装 Oh My Zsh
echo "安装 Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 安装 Powerlevel10k 主题
echo "安装 Powerlevel10k 主题..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# 安装 autojump
echo "安装 autojump..."
sudo apt install -y autojump
echo '. /usr/share/autojump/autojump.sh' >> ~/.zshrc

# 安装 fast-syntax-highlighting 插件
echo "安装 fast-syntax-highlighting 插件..."
git clone https://github.com/z-shell/F-Sy-H.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/F-Sy-H
sed -i '/^plugins=/ s/)/ F-Sy-H)/' ~/.zshrc

# 安装 zsh-autosuggestions 插件
echo "安装 zsh-autosuggestions 插件..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sed -i '/^plugins=/ s/)/ zsh-autosuggestions)/' ~/.zshrc

# 应用 zsh 配置
echo "更新 zsh 配置..."
source ~/.zshrc

# 提示完成
echo "zsh 安装和配置完成！请重启终端以应用所有更改。"