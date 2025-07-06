#!/bin/bash

echo "================================"
echo "一体化构建脚本"
echo "Java安装 + 项目构建"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}环境信息:${NC}"
echo "  系统: $(uname -s)"
echo "  架构: $(uname -m)"
echo "  当前目录: $(pwd)"
echo "  用户: $(whoami)"

# 检查Java
check_java() {
    if command -v java >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Java可用${NC}"
        java -version 2>&1 | head -1
        return 0
    else
        return 1
    fi
}

# 安装Java函数
install_java() {
    echo -e "${YELLOW}开始安装Java...${NC}"

    # 寻找可写目录
    WORK_DIR=""

    # 检查可写目录
    if [ -d "/data/local/tmp" ] && [ -w "/data/local/tmp" ]; then
        WORK_DIR="/data/local/tmp"
    elif [ -d "/sdcard" ] && [ -w "/sdcard" ]; then
        WORK_DIR="/sdcard"
    elif [ -d "/storage/emulated/0" ] && [ -w "/storage/emulated/0" ]; then
        WORK_DIR="/storage/emulated/0"
    else
        mkdir -p "./java-temp" 2>/dev/null
        if [ -w "./java-temp" ]; then
            WORK_DIR="$(pwd)/java-temp"
        fi
    fi
    
    if [ -z "$WORK_DIR" ]; then
        echo -e "${RED}❌ 无法找到可写目录${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ 使用目录: $WORK_DIR${NC}"
    
    # 设置Java目录
    JAVA_DIR="$WORK_DIR/portable-java"
    echo "Java将安装到: $JAVA_DIR"

    mkdir -p "$JAVA_DIR"
    cd "$JAVA_DIR"

    # 检测架构并设置下载信息
    ARCH=$(uname -m)
    JAVA_URL=""
    JAVA_FILE=""
    JAVA_FOLDER=""
    
    case $ARCH in
        "aarch64"|"arm64")
            JAVA_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.8.1_1.tar.gz"
            JAVA_FILE="OpenJDK17U-jdk_aarch64_linux.tar.gz"
            JAVA_FOLDER="jdk-17.0.8.1+1"
            ;;
        "x86_64"|"amd64")
            JAVA_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_x64_linux_hotspot_17.0.8.1_1.tar.gz"
            JAVA_FILE="OpenJDK17U-jdk_x64_linux.tar.gz"
            JAVA_FOLDER="jdk-17.0.8.1+1"
            ;;
        *)
            echo -e "${RED}❌ 不支持的架构: $ARCH${NC}"
            return 1
            ;;
    esac
    
    echo -e "${BLUE}架构: $ARCH${NC}"
    echo "下载URL: $JAVA_URL"
    
    # 下载Java
    if [ -f "$JAVA_FILE" ]; then
        echo -e "${YELLOW}Java文件已存在，跳过下载${NC}"
    else
        echo "正在下载Java..."
        if curl -L -k --progress-bar "$JAVA_URL" -o "$JAVA_FILE"; then
            echo -e "${GREEN}✅ Java下载完成${NC}"
        else
            echo -e "${RED}❌ 下载失败${NC}"
            return 1
        fi
    fi
    
    # 检查文件大小
    FILE_SIZE=$(du -h "$JAVA_FILE" | cut -f1)
    echo "文件大小: $FILE_SIZE"
    
    # 解压Java
    if [ -d "$JAVA_FOLDER" ]; then
        echo -e "${YELLOW}Java已解压，跳过解压${NC}"
    else
        echo "正在解压..."
        if tar -xzf "$JAVA_FILE"; then
            echo -e "${GREEN}✅ Java解压完成${NC}"
        else
            echo -e "${RED}❌ 解压失败${NC}"
            return 1
        fi
    fi
    
    # 验证Java
    JAVA_HOME="$JAVA_DIR/$JAVA_FOLDER"
    JAVA_BIN="$JAVA_HOME/bin/java"
    
    if [ -f "$JAVA_BIN" ] && [ -x "$JAVA_BIN" ]; then
        echo -e "${GREEN}✅ Java可执行文件存在${NC}"
        
        # 测试Java
        echo "测试Java..."
        "$JAVA_BIN" -version
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Java工作正常${NC}"
            
            # 设置环境变量
            export JAVA_HOME="$JAVA_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            
            echo -e "${GREEN}✅ Java环境变量已设置${NC}"
            return 0
        else
            echo -e "${RED}❌ Java无法正常工作${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Java可执行文件不存在${NC}"
        return 1
    fi
}

# 构建项目函数
build_project() {
    echo -e "${YELLOW}开始构建项目...${NC}"
    
    # 返回项目根目录
    cd "$(dirname "$0")"
    
    echo "当前目录: $(pwd)"
    
    # 设置权限
    chmod +x gradlew
    chmod +x *.sh
    
    # 清理项目
    echo "清理项目..."
    if ./gradlew clean; then
        echo -e "${GREEN}✅ 项目清理完成${NC}"
    else
        echo -e "${YELLOW}⚠️  清理失败，继续构建...${NC}"
    fi
    
    # 构建APK
    echo "构建APK..."
    if ./gradlew assembleDebug; then
        echo -e "${GREEN}✅ 构建成功${NC}"
        return 0
    else
        echo -e "${RED}❌ 构建失败${NC}"
        return 1
    fi
}

# 主流程
echo
echo "步骤1: 检查Java环境"
if check_java; then
    echo "Java已可用，跳过安装"
else
    echo -e "${YELLOW}需要安装Java${NC}"
    
    echo
    echo "步骤2: 安装Java"
    if ! install_java; then
        echo -e "${RED}❌ Java安装失败${NC}"
        exit 1
    fi
    
    # 重新检查Java
    if ! check_java; then
        echo -e "${RED}❌ Java安装后仍不可用${NC}"
        exit 1
    fi
fi

echo
echo "步骤3: 构建项目"
if build_project; then
    echo
    echo "================================"
    echo -e "${GREEN}🎉 构建完成！${NC}"
    echo "================================"
    
    # 查找APK文件
    APK_FILES=$(find . -name "*.apk" -type f 2>/dev/null)
    if [ -n "$APK_FILES" ]; then
        echo
        echo -e "${GREEN}生成的APK文件:${NC}"
        for apk in $APK_FILES; do
            echo "  📱 $apk"
            if [ -f "$apk" ]; then
                size=$(du -h "$apk" 2>/dev/null | cut -f1)
                echo "     大小: $size"
            fi
        done
        
        # 尝试复制到存储卡
        FIRST_APK=$(echo $APK_FILES | cut -d' ' -f1)
        for dest_dir in "/sdcard" "/storage/emulated/0" "/data/local/tmp"; do
            if [ -w "$dest_dir" ]; then
                echo
                echo "复制APK到: $dest_dir"
                if cp "$FIRST_APK" "$dest_dir/file-redirect-module.apk"; then
                    echo -e "${GREEN}✅ APK已复制到: $dest_dir/file-redirect-module.apk${NC}"
                    break
                fi
            fi
        done
        
        echo
        echo -e "${BLUE}使用说明:${NC}"
        echo "1. 将APK安装到已Root的Android设备"
        echo "2. 打开Xposed管理器 (LSPosed/EdXposed)"
        echo "3. 在模块列表中找到'文件重定向模块'"
        echo "4. 勾选激活该模块"
        echo "5. 选择作用域 (目标应用)"
        echo "6. 重启设备"
        echo "7. 测试模块效果"
        
        echo
        echo -e "${YELLOW}⚠️  重要提醒:${NC}"
        echo "• 仅用于学习目的"
        echo "• 需要Root权限和Xposed框架"
        echo "• 请勿用于非法用途"
    else
        echo -e "${YELLOW}⚠️  构建成功但未找到APK文件${NC}"
    fi
else
    echo -e "${RED}❌ 构建失败${NC}"
    exit 1
fi

echo
echo "脚本执行完成！"
