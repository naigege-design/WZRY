#!/bin/bash

echo "================================"
echo "环境检查脚本"
echo "================================"

echo
echo "1. 当前目录信息:"
echo "   路径: $(pwd)"
echo "   用户: $(whoami)"

echo
echo "2. 目录内容:"
ls -la

echo
echo "3. 检查必要文件:"

check_file() {
    if [ -f "$1" ]; then
        echo "   ✅ $1 存在"
        if [ -x "$1" ]; then
            echo "      (可执行)"
        else
            echo "      (不可执行)"
        fi
    else
        echo "   ❌ $1 不存在"
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo "   ✅ $1/ 目录存在"
    else
        echo "   ❌ $1/ 目录不存在"
    fi
}

check_file "gradlew"
check_file "gradlew.bat"
check_file "build.gradle"
check_file "settings.gradle"
check_file "gradle.properties"
check_dir "gradle"
check_dir "xposed-module"

echo
echo "4. Java环境:"
if command -v java >/dev/null 2>&1; then
    echo "   ✅ Java已安装"
    java -version 2>&1 | head -3 | sed 's/^/      /'
else
    echo "   ❌ Java未安装"
    echo "      在Termux中安装: pkg install openjdk-17"
fi

echo
echo "5. 系统信息:"
echo "   系统: $(uname -s)"
echo "   架构: $(uname -m)"
if [ -f /etc/os-release ]; then
    echo "   发行版: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
fi

echo
echo "6. 网络连接:"
if ping -c 1 -W 3 google.com >/dev/null 2>&1; then
    echo "   ✅ 网络连接正常 (google.com)"
elif ping -c 1 -W 3 baidu.com >/dev/null 2>&1; then
    echo "   ✅ 网络连接正常 (baidu.com)"
else
    echo "   ❌ 网络连接可能有问题"
fi

echo
echo "7. 磁盘空间:"
df -h . | tail -1 | awk '{print "   可用空间: " $4 " (使用率: " $5 ")"}'

echo
echo "8. 权限检查:"
if [ -w . ]; then
    echo "   ✅ 当前目录可写"
else
    echo "   ❌ 当前目录不可写"
fi

echo
echo "================================"
echo "检查完成"
echo "================================"

echo
echo "如果发现问题，请按以下步骤解决:"
echo
echo "缺少gradlew文件:"
echo "  - 确保您下载了完整的项目文件"
echo "  - 检查文件是否被正确提取"
echo
echo "Java未安装 (Termux):"
echo "  pkg update"
echo "  pkg install openjdk-17"
echo
echo "权限问题:"
echo "  chmod +x gradlew"
echo "  chmod +x *.sh"
echo
echo "网络问题:"
echo "  - 检查网络连接"
echo "  - 尝试使用移动数据或WiFi"
echo
echo "磁盘空间不足:"
echo "  - 清理不必要的文件"
echo "  - 确保至少有1GB可用空间"
