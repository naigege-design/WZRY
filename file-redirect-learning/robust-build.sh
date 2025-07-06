#!/bin/bash

echo "================================"
echo "稳定构建脚本 (带重试机制)"
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

# 下载函数，带重试机制
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "尝试下载 (第 $attempt/$max_attempts 次)..."
        
        # 使用curl下载，带超时和重试参数
        if curl -L -k --connect-timeout 30 --max-time 600 --retry 3 --retry-delay 5 \
                --progress-bar "$url" -o "$output"; then
            echo -e "${GREEN}✅ 下载成功${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  下载失败，尝试 $attempt/$max_attempts${NC}"
            
            # 删除不完整的文件
            [ -f "$output" ] && rm -f "$output"
            
            attempt=$((attempt + 1))
            
            if [ $attempt -le $max_attempts ]; then
                echo "等待5秒后重试..."
                sleep 5
            fi
        fi
    done
    
    echo -e "${RED}❌ 所有下载尝试都失败了${NC}"
    return 1
}

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
    
    # 多个下载源
    JAVA_FILE="OpenJDK17U-jdk_aarch64_linux.tar.gz"
    JAVA_FOLDER="jdk-17.0.8.1+1"
    
    # 备用下载源列表
    DOWNLOAD_URLS=(
        "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.8.1_1.tar.gz"
        "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-aarch64_bin.tar.gz"
        "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.7%2B7/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.7_7.tar.gz"
    )
    
    # 检查是否已有文件
    if [ -f "$JAVA_FILE" ]; then
        echo -e "${YELLOW}Java文件已存在，检查完整性...${NC}"
        
        # 检查文件大小（应该至少50MB）
        FILE_SIZE_BYTES=$(stat -c%s "$JAVA_FILE" 2>/dev/null || stat -f%z "$JAVA_FILE" 2>/dev/null)
        if [ "$FILE_SIZE_BYTES" -lt 50000000 ]; then
            echo -e "${YELLOW}文件不完整，重新下载...${NC}"
            rm -f "$JAVA_FILE"
        else
            echo -e "${GREEN}文件完整，跳过下载${NC}"
        fi
    fi
    
    # 如果文件不存在，尝试下载
    if [ ! -f "$JAVA_FILE" ]; then
        echo "正在尝试多个下载源..."
        
        download_success=false
        for url in "${DOWNLOAD_URLS[@]}"; do
            echo
            echo -e "${BLUE}尝试下载源: $url${NC}"
            
            if download_with_retry "$url" "$JAVA_FILE"; then
                download_success=true
                break
            else
                echo -e "${YELLOW}此下载源失败，尝试下一个...${NC}"
            fi
        done
        
        if [ "$download_success" = false ]; then
            echo -e "${RED}❌ 所有下载源都失败了${NC}"
            echo
            echo "手动下载方法:"
            echo "1. 在浏览器中打开以下任一链接:"
            for url in "${DOWNLOAD_URLS[@]}"; do
                echo "   $url"
            done
            echo "2. 下载文件并重命名为: $JAVA_FILE"
            echo "3. 将文件放到: $JAVA_DIR/"
            echo "4. 重新运行此脚本"
            exit 1
        fi
    fi
    
    # 检查最终文件大小
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
            echo "可能的原因:"
            echo "1. 文件损坏，请重新下载"
            echo "2. 磁盘空间不足"
            echo "3. 权限问题"
            exit 1
        fi
    fi
    
    # 查找实际的JDK目录（可能名称不同）
    JDK_DIRS=$(find . -maxdepth 1 -type d -name "jdk*" | head -1)
    if [ -n "$JDK_DIRS" ]; then
        JAVA_FOLDER=$(basename "$JDK_DIRS")
        echo "找到JDK目录: $JAVA_FOLDER"
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
        echo "查找可能的java文件:"
        find "$JAVA_HOME" -name "java" -type f 2>/dev/null | head -5
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
