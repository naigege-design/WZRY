#!/bin/bash

echo "================================"
echo "文件重定向模块构建器"
echo "================================"

# 设置所有脚本的执行权限
echo "设置脚本权限..."
chmod +x *.sh
chmod +x gradlew

echo "当前目录: $(pwd)"
echo "可用脚本:"
ls -la *.sh | grep -E "^-rwx" | awk '{print "  ✅ " $9}'

echo
echo "选择构建方式:"
echo "1. 一体化构建 (推荐)"
echo "2. 检查环境"
echo "3. 手动步骤"
echo

read -p "请选择 (1-3): " choice

case $choice in
    1)
        echo "启动一体化构建..."
        ./all-in-one-build.sh
        ;;
    2)
        echo "检查环境..."
        ./diagnose-java-install.sh
        ;;
    3)
        echo "手动步骤:"
        echo "1. 检查环境: ./diagnose-java-install.sh"
        echo "2. 安装Java: ./install-java-tmp.sh"
        echo "3. 构建项目: ./build-with-temp-java.sh"
        ;;
    *)
        echo "默认使用一体化构建..."
        ./all-in-one-build.sh
        ;;
esac
