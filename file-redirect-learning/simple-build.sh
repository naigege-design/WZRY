#!/bin/bash

echo "================================"
echo "简化构建脚本"
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
echo
echo "步骤1: 检查Java环境"
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Java已可用${NC}"
    java -version 2>&1 | head -1
else
    echo -e "${YELLOW}需要安装Java${NC}"
    
    echo
    echo "步骤2: 安装Java"
    
    # 设置工作目录
    WORK_DIR="/data/local/tmp"
    if [ ! -w "$WORK_DIR" ]; then
        WORK_DIR="$(pwd)/java-temp"
        mkdir -p "$WORK_DIR"
    fi
    
    JAVA_DIR="$WORK_DIR/portable-java"
    echo "Java将安装到: $JAVA_DIR"
    
    mkdir -p "$JAVA_DIR"
    cd "$JAVA_DIR"
    
    # 设置下载信息 (ARM64)
    JAVA_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.8.1_1.tar.gz"
    JAVA_FILE="OpenJDK17U-jdk_aarch64_linux.tar.gz"
    JAVA_FOLDER="jdk-17.0.8.1+1"
    
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
            exit 1
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
            exit 1
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
        else
            echo -e "${RED}❌ Java无法正常工作${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Java可执行文件不存在${NC}"
        exit 1
    fi
fi

# 返回项目根目录
cd "$(dirname "$0")"

echo
echo "步骤3: 构建项目"
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
        if [ -w "/sdcard" ]; then
            echo
            echo "复制APK到存储卡..."
            if cp "$FIRST_APK" "/sdcard/file-redirect-module.apk"; then
                echo -e "${GREEN}✅ APK已复制到: /sdcard/file-redirect-module.apk${NC}"
            fi
        elif [ -w "/storage/emulated/0" ]; then
            echo
            echo "复制APK到存储卡..."
            if cp "$FIRST_APK" "/storage/emulated/0/file-redirect-module.apk"; then
                echo -e "${GREEN}✅ APK已复制到: /storage/emulated/0/file-redirect-module.apk${NC}"
            fi
        fi
        
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
