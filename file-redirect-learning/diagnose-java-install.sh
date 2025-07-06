#!/bin/bash

echo "================================"
echo "Java安装诊断脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "1. 检查Java安装目录:"
JAVA_DIR="$HOME/portable-java"
echo "   预期目录: $JAVA_DIR"

if [ -d "$JAVA_DIR" ]; then
    echo -e "   ✅ Java目录存在"
    echo "   目录内容:"
    ls -la "$JAVA_DIR" | sed 's/^/      /'
else
    echo -e "   ❌ Java目录不存在"
fi

echo
echo "2. 检查下载的文件:"
if [ -d "$JAVA_DIR" ]; then
    cd "$JAVA_DIR"
    echo "   当前目录: $(pwd)"
    
    # 检查tar.gz文件
    TAR_FILES=$(ls *.tar.gz 2>/dev/null)
    if [ -n "$TAR_FILES" ]; then
        echo -e "   ✅ 找到压缩文件:"
        for file in $TAR_FILES; do
            echo "      📦 $file ($(du -h "$file" | cut -f1))"
        done
    else
        echo -e "   ❌ 未找到压缩文件"
    fi
    
    # 检查解压后的目录
    JDK_DIRS=$(ls -d jdk-* 2>/dev/null)
    if [ -n "$JDK_DIRS" ]; then
        echo -e "   ✅ 找到JDK目录:"
        for dir in $JDK_DIRS; do
            echo "      📁 $dir"
            if [ -f "$dir/bin/java" ]; then
                echo "         ✅ java可执行文件存在"
                echo "         版本: $("$dir/bin/java" -version 2>&1 | head -1)"
            else
                echo "         ❌ java可执行文件不存在"
            fi
        done
    else
        echo -e "   ❌ 未找到JDK目录"
    fi
fi

echo
echo "3. 检查网络和下载工具:"
if command -v wget >/dev/null 2>&1; then
    echo -e "   ✅ wget可用"
elif command -v curl >/dev/null 2>&1; then
    echo -e "   ✅ curl可用"
else
    echo -e "   ❌ wget和curl都不可用"
fi

# 测试网络连接
echo "   测试网络连接:"
if ping -c 1 -W 3 google.com >/dev/null 2>&1; then
    echo -e "      ✅ 网络连接正常"
elif ping -c 1 -W 3 baidu.com >/dev/null 2>&1; then
    echo -e "      ✅ 网络连接正常 (国内)"
else
    echo -e "      ❌ 网络连接可能有问题"
fi

echo
echo "4. 检查磁盘空间:"
echo "   当前目录可用空间: $(df -h . 2>/dev/null | tail -1 | awk '{print $4}' || echo '未知')"
echo "   HOME目录可用空间: $(df -h "$HOME" 2>/dev/null | tail -1 | awk '{print $4}' || echo '未知')"

echo
echo "5. 检查权限:"
if [ -w "$HOME" ]; then
    echo -e "   ✅ HOME目录可写"
else
    echo -e "   ❌ HOME目录不可写"
fi

if [ -d "$JAVA_DIR" ] && [ -w "$JAVA_DIR" ]; then
    echo -e "   ✅ Java目录可写"
elif [ -d "$JAVA_DIR" ]; then
    echo -e "   ❌ Java目录不可写"
fi

echo
echo "6. 环境变量检查:"
echo "   HOME: $HOME"
echo "   PATH: $PATH"
echo "   JAVA_HOME: ${JAVA_HOME:-未设置}"

if [ -f "$HOME/java-env.sh" ]; then
    echo -e "   ✅ 环境变量脚本存在: $HOME/java-env.sh"
    echo "   内容:"
    cat "$HOME/java-env.sh" | sed 's/^/      /'
else
    echo -e "   ❌ 环境变量脚本不存在"
fi

echo
echo "================================"
echo "诊断完成"
echo "================================"

# 提供修复建议
echo
echo "修复建议:"

if [ ! -d "$JAVA_DIR" ]; then
    echo "1. Java目录不存在，需要重新创建:"
    echo "   mkdir -p $JAVA_DIR"
fi

if [ -d "$JAVA_DIR" ]; then
    cd "$JAVA_DIR"
    if [ ! -f "*.tar.gz" ] && [ ! -d "jdk-*" ]; then
        echo "2. 需要重新下载Java:"
        echo "   cd $JAVA_DIR"
        echo "   # 然后手动下载或重新运行安装脚本"
    fi
    
    TAR_FILE=$(ls *.tar.gz 2>/dev/null | head -1)
    if [ -n "$TAR_FILE" ] && [ ! -d "jdk-*" ]; then
        echo "3. 需要解压Java:"
        echo "   cd $JAVA_DIR"
        echo "   tar -xzf $TAR_FILE"
    fi
fi

echo
echo "快速修复命令:"
echo "./fix-java-install.sh"
