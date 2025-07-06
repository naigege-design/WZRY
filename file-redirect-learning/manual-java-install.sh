#!/bin/bash

echo "================================"
echo "手动Java安装指导"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}请根据您的环境选择安装方法:${NC}"
echo

echo "1️⃣  Termux环境:"
echo "   pkg update"
echo "   pkg install openjdk-17"
echo "   # 或者尝试: pkg install openjdk-11"
echo "   # 或者尝试: pkg install openjdk-8"
echo

echo "2️⃣  Ubuntu/Debian环境:"
echo "   sudo apt update"
echo "   sudo apt install openjdk-17-jdk"
echo "   # 或者: sudo apt install default-jdk"
echo

echo "3️⃣  CentOS/RHEL环境:"
echo "   sudo yum install java-17-openjdk-devel"
echo "   # 或者: sudo dnf install java-17-openjdk-devel"
echo

echo "4️⃣  Alpine Linux:"
echo "   apk update"
echo "   apk add openjdk17"
echo

echo "5️⃣  Arch Linux:"
echo "   sudo pacman -S jdk-openjdk"
echo

echo "6️⃣  如果以上都不行，尝试下载便携版Java:"
echo "   # 创建java目录"
echo "   mkdir -p ~/java"
echo "   cd ~/java"
echo "   "
echo "   # 下载OpenJDK (根据您的架构选择)"
echo "   # ARM64:"
echo "   wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-aarch64_bin.tar.gz"
echo "   "
echo "   # x86_64:"
echo "   wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz"
echo "   "
echo "   # 解压"
echo "   tar -xzf openjdk-*.tar.gz"
echo "   "
echo "   # 设置环境变量"
echo "   export JAVA_HOME=~/java/jdk-17.0.2"
echo "   export PATH=\$JAVA_HOME/bin:\$PATH"
echo

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}自动尝试安装${NC}"
echo -e "${YELLOW}================================${NC}"

echo "正在尝试自动安装Java..."

# 尝试各种安装方法
install_success=false

# 方法1: pkg (Termux)
if command -v pkg >/dev/null 2>&1; then
    echo -e "${BLUE}尝试使用pkg安装...${NC}"
    if pkg install openjdk-17 -y 2>/dev/null; then
        echo -e "${GREEN}✅ pkg install openjdk-17 成功${NC}"
        install_success=true
    elif pkg install openjdk-11 -y 2>/dev/null; then
        echo -e "${GREEN}✅ pkg install openjdk-11 成功${NC}"
        install_success=true
    elif pkg install openjdk-8 -y 2>/dev/null; then
        echo -e "${GREEN}✅ pkg install openjdk-8 成功${NC}"
        install_success=true
    else
        echo -e "${RED}❌ pkg安装失败${NC}"
    fi
fi

# 方法2: apt (Ubuntu/Debian)
if ! $install_success && command -v apt >/dev/null 2>&1; then
    echo -e "${BLUE}尝试使用apt安装...${NC}"
    if sudo apt update && sudo apt install -y openjdk-17-jdk 2>/dev/null; then
        echo -e "${GREEN}✅ apt install openjdk-17-jdk 成功${NC}"
        install_success=true
    elif sudo apt install -y default-jdk 2>/dev/null; then
        echo -e "${GREEN}✅ apt install default-jdk 成功${NC}"
        install_success=true
    else
        echo -e "${RED}❌ apt安装失败${NC}"
    fi
fi

# 方法3: yum (CentOS/RHEL)
if ! $install_success && command -v yum >/dev/null 2>&1; then
    echo -e "${BLUE}尝试使用yum安装...${NC}"
    if sudo yum install -y java-17-openjdk-devel 2>/dev/null; then
        echo -e "${GREEN}✅ yum install java-17-openjdk-devel 成功${NC}"
        install_success=true
    else
        echo -e "${RED}❌ yum安装失败${NC}"
    fi
fi

# 方法4: apk (Alpine)
if ! $install_success && command -v apk >/dev/null 2>&1; then
    echo -e "${BLUE}尝试使用apk安装...${NC}"
    if apk update && apk add openjdk17 2>/dev/null; then
        echo -e "${GREEN}✅ apk add openjdk17 成功${NC}"
        install_success=true
    else
        echo -e "${RED}❌ apk安装失败${NC}"
    fi
fi

# 验证安装
echo
echo "验证Java安装..."
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Java安装成功！${NC}"
    java -version
    install_success=true
else
    echo -e "${RED}❌ Java安装失败${NC}"
    install_success=false
fi

echo
if $install_success; then
    echo -e "${GREEN}🎉 Java安装完成！现在可以构建项目了${NC}"
    echo
    echo "运行以下命令开始构建:"
    echo "  ./build-mobile.sh"
else
    echo -e "${RED}❌ 自动安装失败${NC}"
    echo
    echo -e "${YELLOW}请手动安装Java:${NC}"
    echo "1. 确定您的系统类型"
    echo "2. 使用对应的包管理器安装Java"
    echo "3. 或者下载便携版Java并设置环境变量"
    echo
    echo "需要帮助？请运行: ./detect-environment.sh"
fi
