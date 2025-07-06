#!/bin/bash

echo "================================"
echo "最终构建脚本 (网络优化版)"
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
download_file() {
    local url="$1"
    local output="$2"
    local attempt=1
    local max_attempts=3
    
    while [ $attempt -le $max_attempts ]; do
        echo "下载尝试 $attempt/$max_attempts..."
        
        # 使用curl下载，分段下载以避免超时
        if curl -L -k --connect-timeout 30 --max-time 1200 \
                --retry 2 --retry-delay 3 \
                --progress-bar "$url" -o "$output"; then
            
            # 检查文件大小
            if [ -f "$output" ]; then
                FILE_SIZE_BYTES=$(stat -c%s "$output" 2>/dev/null || stat -f%z "$output" 2>/dev/null)
                if [ "$FILE_SIZE_BYTES" -gt 50000000 ]; then
                    echo -e "${GREEN}✅ 下载成功${NC}"
                    return 0
                else
                    echo -e "${YELLOW}文件太小，可能不完整${NC}"
                fi
            fi
        fi
        
        echo -e "${YELLOW}下载失败，清理文件...${NC}"
        [ -f "$output" ] && rm -f "$output"
        
        attempt=$((attempt + 1))
        if [ $attempt -le $max_attempts ]; then
            echo "等待10秒后重试..."
            sleep 10
        fi
    done
    
    return 1
}

# 尝试多个下载源
try_download_sources() {
    local output="$1"
    
    echo "尝试下载源1: GitHub Adoptium (推荐)"
    if download_file "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.8.1_1.tar.gz" "$output"; then
        return 0
    fi
    
    echo
    echo "尝试下载源2: Oracle OpenJDK"
    if download_file "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-aarch64_bin.tar.gz" "$output"; then
        return 0
    fi
    
    echo
    echo "尝试下载源3: GitHub Adoptium (旧版本)"
    if download_file "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.7%2B7/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.7_7.tar.gz" "$output"; then
        return 0
    fi
    
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
    
    JAVA_FILE="OpenJDK17U-jdk_aarch64_linux.tar.gz"
    
    # 检查现有文件
    if [ -f "$JAVA_FILE" ]; then
        echo -e "${YELLOW}检查现有文件...${NC}"
        FILE_SIZE_BYTES=$(stat -c%s "$JAVA_FILE" 2>/dev/null || stat -f%z "$JAVA_FILE" 2>/dev/null)
        if [ "$FILE_SIZE_BYTES" -lt 50000000 ]; then
            echo -e "${YELLOW}文件不完整，重新下载...${NC}"
            rm -f "$JAVA_FILE"
        else
            echo -e "${GREEN}文件完整，跳过下载${NC}"
        fi
    fi
    
    # 下载Java
    if [ ! -f "$JAVA_FILE" ]; then
        echo "开始下载Java..."
        
        if try_download_sources "$JAVA_FILE"; then
            echo -e "${GREEN}✅ Java下载成功${NC}"
        else
            echo -e "${RED}❌ 所有下载源都失败了${NC}"
            echo
            echo "网络问题解决方案:"
            echo "1. 检查网络连接"
            echo "2. 尝试使用移动数据"
            echo "3. 稍后重试"
            echo "4. 手动下载:"
            echo "   - 浏览器打开: https://adoptium.net/temurin/releases/"
            echo "   - 选择: OpenJDK 17 (LTS)"
            echo "   - 平台: Linux"
            echo "   - 架构: aarch64"
            echo "   - 下载后重命名为: $JAVA_FILE"
            echo "   - 放到目录: $JAVA_DIR/"
            exit 1
        fi
    fi
    
    # 显示文件信息
    FILE_SIZE=$(du -h "$JAVA_FILE" | cut -f1)
    echo "Java文件大小: $FILE_SIZE"
    
    # 解压Java
    echo "解压Java..."
    if tar -xzf "$JAVA_FILE"; then
        echo -e "${GREEN}✅ Java解压完成${NC}"
    else
        echo -e "${RED}❌ 解压失败${NC}"
        echo "可能原因:"
        echo "1. 文件损坏 - 请删除文件重新下载"
        echo "2. 磁盘空间不足 - 请清理空间"
        echo "3. 权限问题 - 请检查目录权限"
        exit 1
    fi
    
    # 查找JDK目录
    JDK_DIR=$(find . -maxdepth 1 -type d -name "jdk*" | head -1)
    if [ -z "$JDK_DIR" ]; then
        echo -e "${RED}❌ 未找到JDK目录${NC}"
        echo "目录内容:"
        ls -la
        exit 1
    fi
    
    JAVA_FOLDER=$(basename "$JDK_DIR")
    echo "JDK目录: $JAVA_FOLDER"
    
    # 验证Java
    JAVA_HOME="$JAVA_DIR/$JAVA_FOLDER"
    JAVA_BIN="$JAVA_HOME/bin/java"
    
    echo "验证Java安装..."
    echo "JAVA_HOME: $JAVA_HOME"
    echo "Java可执行文件: $JAVA_BIN"
    
    if [ -f "$JAVA_BIN" ] && [ -x "$JAVA_BIN" ]; then
        echo -e "${GREEN}✅ Java可执行文件存在${NC}"
        
        # 测试Java
        echo "测试Java..."
        if "$JAVA_BIN" -version; then
            echo -e "${GREEN}✅ Java工作正常${NC}"
            
            # 设置环境变量
            export JAVA_HOME="$JAVA_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            
            echo -e "${GREEN}✅ Java环境已设置${NC}"
        else
            echo -e "${RED}❌ Java测试失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Java可执行文件不存在或无权限${NC}"
        echo "查找java文件:"
        find "$JAVA_HOME" -name "java" -type f 2>/dev/null
        exit 1
    fi
fi

# 返回项目目录
cd "$(dirname "$0")"

echo
echo "步骤3: 构建项目"
echo "当前目录: $(pwd)"

# 设置权限
chmod +x gradlew 2>/dev/null
chmod +x *.sh 2>/dev/null

# 验证Java环境
echo "最终验证Java环境..."
if command -v java >/dev/null 2>&1; then
    java -version
else
    echo -e "${RED}❌ Java环境设置失败${NC}"
    exit 1
fi

# 清理项目
echo
echo "清理项目..."
if ./gradlew clean; then
    echo -e "${GREEN}✅ 项目清理完成${NC}"
else
    echo -e "${YELLOW}⚠️  清理失败，继续构建...${NC}"
fi

# 构建APK
echo
echo "构建APK (这可能需要几分钟)..."
if ./gradlew assembleDebug; then
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
            size=$(du -h "$apk" 2>/dev/null | cut -f1)
            echo "     大小: $size"
        done
        
        # 复制到存储卡
        FIRST_APK=$(echo $APK_FILES | cut -d' ' -f1)
        if [ -w "/sdcard" ]; then
            cp "$FIRST_APK" "/sdcard/file-redirect-module.apk" 2>/dev/null && \
            echo -e "${GREEN}✅ APK已复制到: /sdcard/file-redirect-module.apk${NC}"
        elif [ -w "/storage/emulated/0" ]; then
            cp "$FIRST_APK" "/storage/emulated/0/file-redirect-module.apk" 2>/dev/null && \
            echo -e "${GREEN}✅ APK已复制到: /storage/emulated/0/file-redirect-module.apk${NC}"
        fi
        
        echo
        echo -e "${BLUE}安装说明:${NC}"
        echo "1. 安装APK到已Root的Android设备"
        echo "2. 打开Xposed管理器 (LSPosed/EdXposed)"
        echo "3. 激活'文件重定向模块'"
        echo "4. 选择作用域 (目标应用)"
        echo "5. 重启设备"
        echo "6. 测试效果"
        
    else
        echo -e "${YELLOW}⚠️  未找到APK文件${NC}"
    fi
else
    echo -e "${RED}❌ 构建失败${NC}"
    echo
    echo "常见问题:"
    echo "1. 网络问题 - 检查网络连接"
    echo "2. 磁盘空间 - 确保有足够空间"
    echo "3. Java问题 - 重新运行脚本"
    exit 1
fi

echo
echo "脚本执行完成！"
