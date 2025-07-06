#!/bin/bash

echo "================================"
echo "终极构建脚本"
echo "尝试多种Java解决方案"
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
echo "  内核: $(uname -r)"
echo "  当前目录: $(pwd)"

# 方案1: 检查系统Java
echo
echo "方案1: 检查系统Java"
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 系统Java可用${NC}"
    java -version
    JAVA_AVAILABLE=true
else
    echo "❌ 系统Java不可用"
    JAVA_AVAILABLE=false
fi

# 方案2: 尝试修复已下载的Java
if [ "$JAVA_AVAILABLE" = false ]; then
    echo
    echo "方案2: 修复已下载的Java"
    JAVA_DIR="/data/file-redirect-learning/java-temp/portable-java/jdk-17.0.8.1+1"
    JAVA_BIN="$JAVA_DIR/bin/java"
    
    if [ -f "$JAVA_BIN" ]; then
        echo "设置Java权限..."
        chmod +x "$JAVA_BIN"
        chmod +x "$JAVA_DIR/bin/"*
        
        # 尝试执行
        echo "测试Java..."
        if "$JAVA_BIN" -version >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Java修复成功${NC}"
            export JAVA_HOME="$JAVA_DIR"
            export PATH="$JAVA_HOME/bin:$PATH"
            JAVA_AVAILABLE=true
        else
            echo "❌ Java仍无法工作"
            echo "文件信息:"
            ls -la "$JAVA_BIN"
            file "$JAVA_BIN" 2>/dev/null || echo "无法检测文件类型"
        fi
    else
        echo "❌ Java文件不存在"
    fi
fi

# 方案3: 下载OpenJDK 8 (更兼容)
if [ "$JAVA_AVAILABLE" = false ]; then
    echo
    echo "方案3: 下载OpenJDK 8 (更兼容)"
    
    JAVA8_DIR="/data/file-redirect-learning/java-temp/openjdk8"
    mkdir -p "$JAVA8_DIR"
    cd "$JAVA8_DIR"
    
    JAVA8_URL="https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u382-b05/OpenJDK8U-jdk_aarch64_linux_hotspot_8u382b05.tar.gz"
    JAVA8_FILE="openjdk8.tar.gz"
    
    if [ ! -f "$JAVA8_FILE" ]; then
        echo "下载OpenJDK 8..."
        if curl -L -k --connect-timeout 30 --max-time 600 "$JAVA8_URL" -o "$JAVA8_FILE"; then
            echo -e "${GREEN}✅ OpenJDK 8下载成功${NC}"
        else
            echo "❌ OpenJDK 8下载失败"
        fi
    fi
    
    if [ -f "$JAVA8_FILE" ]; then
        echo "解压OpenJDK 8..."
        if tar -xzf "$JAVA8_FILE"; then
            echo -e "${GREEN}✅ OpenJDK 8解压成功${NC}"
            
            # 查找JDK目录
            JDK8_DIR=$(find . -maxdepth 1 -type d -name "*jdk*" | head -1)
            if [ -n "$JDK8_DIR" ]; then
                JAVA8_BIN="$JAVA8_DIR/$JDK8_DIR/bin/java"
                chmod +x "$JAVA8_BIN"
                
                echo "测试OpenJDK 8..."
                if "$JAVA8_BIN" -version >/dev/null 2>&1; then
                    echo -e "${GREEN}✅ OpenJDK 8工作正常${NC}"
                    export JAVA_HOME="$JAVA8_DIR/$JDK8_DIR"
                    export PATH="$JAVA_HOME/bin:$PATH"
                    JAVA_AVAILABLE=true
                else
                    echo "❌ OpenJDK 8也无法工作"
                fi
            fi
        fi
    fi
fi

# 方案4: 尝试使用Android的Java
if [ "$JAVA_AVAILABLE" = false ]; then
    echo
    echo "方案4: 查找Android系统Java"
    
    ANDROID_JAVA_PATHS=(
        "/system/bin/dalvikvm"
        "/apex/com.android.art/bin/dalvikvm64"
        "/apex/com.android.runtime/bin/dalvikvm64"
    )
    
    for java_path in "${ANDROID_JAVA_PATHS[@]}"; do
        if [ -f "$java_path" ] && [ -x "$java_path" ]; then
            echo -e "${YELLOW}找到Android Java: $java_path${NC}"
            # 注意：dalvikvm不是标准Java，可能无法用于编译
        fi
    done
fi

# 检查最终Java状态
echo
echo "最终Java状态检查:"
if [ "$JAVA_AVAILABLE" = true ] && command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Java环境可用${NC}"
    java -version
else
    echo -e "${RED}❌ 无可用的Java环境${NC}"
    echo
    echo "建议解决方案:"
    echo "1. 在电脑上使用Android Studio编译"
    echo "2. 使用Termux环境 (pkg install openjdk-17)"
    echo "3. 使用Linux Deploy或UserLAnd"
    echo "4. 检查设备是否支持Java运行时"
    echo
    echo "当前环境可能不支持Java运行时。"
    exit 1
fi

# 开始构建项目
echo
echo "================================"
echo "开始构建项目"
echo "================================"

cd /data/file-redirect-learning

# 设置权限
chmod +x gradlew
chmod +x *.sh

echo "清理项目..."
if ./gradlew clean; then
    echo -e "${GREEN}✅ 清理成功${NC}"
else
    echo -e "${YELLOW}⚠️  清理失败，继续构建${NC}"
fi

echo
echo "构建APK (这可能需要几分钟)..."
if ./gradlew assembleDebug; then
    echo
    echo "================================"
    echo -e "${GREEN}🎉 构建成功！${NC}"
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
            cp "$FIRST_APK" "/sdcard/file-redirect-module.apk" && \
            echo -e "${GREEN}✅ APK已复制到: /sdcard/file-redirect-module.apk${NC}"
        elif [ -w "/storage/emulated/0" ]; then
            cp "$FIRST_APK" "/storage/emulated/0/file-redirect-module.apk" && \
            echo -e "${GREEN}✅ APK已复制到: /storage/emulated/0/file-redirect-module.apk${NC}"
        fi
        
        echo
        echo "================================"
        echo -e "${GREEN}🎉 构建完成！${NC}"
        echo "================================"
        echo
        echo -e "${YELLOW}安装和使用说明:${NC}"
        echo "1. 安装APK到已Root的Android设备"
        echo "2. 打开Xposed管理器 (LSPosed/EdXposed)"
        echo "3. 激活'文件重定向模块'"
        echo "4. 选择作用域 (目标应用)"
        echo "5. 重启设备"
        echo "6. 测试模块效果"
        echo
        echo -e "${YELLOW}⚠️  重要提醒:${NC}"
        echo "• 仅用于学习目的"
        echo "• 需要Root权限和Xposed框架"
        echo "• 请勿用于非法用途"
        
    else
        echo -e "${YELLOW}⚠️  构建成功但未找到APK文件${NC}"
    fi
    
else
    echo
    echo -e "${RED}❌ 构建失败${NC}"
    echo
    echo "可能的问题:"
    echo "1. Java环境不兼容"
    echo "2. 网络连接问题"
    echo "3. 磁盘空间不足"
    echo "4. 系统限制"
    
    exit 1
fi

echo
echo "脚本执行完成！"
