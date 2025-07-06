#!/bin/bash

echo "================================"
echo "环境检测脚本"
echo "================================"

echo "1. 系统信息:"
echo "   操作系统: $(uname -s)"
echo "   架构: $(uname -m)"
echo "   内核版本: $(uname -r)"

echo
echo "2. 发行版信息:"
if [ -f /etc/os-release ]; then
    echo "   发行版: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    echo "   ID: $(grep '^ID=' /etc/os-release | cut -d'=' -f2)"
    echo "   版本: $(grep VERSION_ID /etc/os-release | cut -d'"' -f2)"
elif [ -f /system/build.prop ]; then
    echo "   Android系统"
    echo "   版本: $(getprop ro.build.version.release 2>/dev/null || echo '未知')"
fi

echo
echo "3. 可用的包管理器:"
managers=("pkg" "apt" "apt-get" "yum" "dnf" "pacman" "zypper" "apk")
for manager in "${managers[@]}"; do
    if command -v "$manager" >/dev/null 2>&1; then
        echo "   ✅ $manager"
    else
        echo "   ❌ $manager"
    fi
done

echo
echo "4. Shell环境:"
echo "   当前Shell: $SHELL"
echo "   用户: $(whoami)"
echo "   HOME: $HOME"

echo
echo "5. 环境变量:"
echo "   PATH: $PATH"
echo "   PREFIX: ${PREFIX:-未设置}"
echo "   ANDROID_DATA: ${ANDROID_DATA:-未设置}"

echo
echo "6. 特殊目录检查:"
dirs=("/data/data/com.termux" "/system" "/data/local/tmp" "/sdcard")
for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "   ✅ $dir 存在"
    else
        echo "   ❌ $dir 不存在"
    fi
done

echo
echo "7. Java相关检查:"
java_paths=("/usr/bin/java" "/system/bin/java" "$PREFIX/bin/java" "/data/data/com.termux/files/usr/bin/java")
for java_path in "${java_paths[@]}"; do
    if [ -f "$java_path" ]; then
        echo "   ✅ 找到Java: $java_path"
        "$java_path" -version 2>&1 | head -1 | sed 's/^/      /'
    fi
done

if command -v java >/dev/null 2>&1; then
    echo "   ✅ Java在PATH中可用"
    java -version 2>&1 | head -1 | sed 's/^/      /'
else
    echo "   ❌ Java不在PATH中"
fi

echo
echo "================================"
echo "环境检测完成"
echo "================================"
