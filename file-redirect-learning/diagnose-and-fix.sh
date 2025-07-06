#!/bin/bash

echo "================================"
echo "Java诊断和修复脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

JAVA_DIR="/data/file-redirect-learning/java-temp/portable-java/jdk-17.0.8.1+1"
JAVA_BIN="$JAVA_DIR/bin/java"

echo "诊断Java安装问题..."
echo "Java目录: $JAVA_DIR"
echo "Java可执行文件: $JAVA_BIN"

echo
echo "1. 检查文件存在性:"
if [ -f "$JAVA_BIN" ]; then
    echo -e "  ✅ Java文件存在"
else
    echo -e "  ❌ Java文件不存在"
    echo "  查找Java文件:"
    find /data/file-redirect-learning/java-temp -name "java" -type f 2>/dev/null
    exit 1
fi

echo
echo "2. 检查文件权限:"
ls -la "$JAVA_BIN"
echo "设置执行权限..."
chmod +x "$JAVA_BIN"
chmod +x "$JAVA_DIR/bin/"*
echo "权限设置后:"
ls -la "$JAVA_BIN"

echo
echo "3. 检查文件类型:"
file "$JAVA_BIN"

echo
echo "4. 检查架构兼容性:"
echo "系统架构: $(uname -m)"
if command -v readelf >/dev/null 2>&1; then
    echo "Java文件架构:"
    readelf -h "$JAVA_BIN" 2>/dev/null | grep Machine || echo "无法读取架构信息"
fi

echo
echo "5. 检查依赖库:"
if command -v ldd >/dev/null 2>&1; then
    echo "Java依赖库:"
    ldd "$JAVA_BIN" 2>/dev/null | head -10 || echo "无法检查依赖库"
fi

echo
echo "6. 尝试不同的执行方法:"

echo "方法1: 直接执行"
"$JAVA_BIN" -version 2>&1 && echo -e "${GREEN}✅ 直接执行成功${NC}" || echo -e "${RED}❌ 直接执行失败${NC}"

echo
echo "方法2: 使用绝对路径"
/data/file-redirect-learning/java-temp/portable-java/jdk-17.0.8.1+1/bin/java -version 2>&1 && echo -e "${GREEN}✅ 绝对路径成功${NC}" || echo -e "${RED}❌ 绝对路径失败${NC}"

echo
echo "方法3: 检查shell环境"
echo "当前shell: $SHELL"
echo "PATH: $PATH"

echo
echo "方法4: 尝试使用sh执行"
sh -c "$JAVA_BIN -version" 2>&1 && echo -e "${GREEN}✅ sh执行成功${NC}" || echo -e "${RED}❌ sh执行失败${NC}"

echo
echo "7. 检查系统兼容性:"
echo "内核版本: $(uname -r)"
echo "系统信息: $(uname -a)"

# 检查是否在容器中
if [ -f /.dockerenv ]; then
    echo "⚠️  检测到Docker容器环境"
elif [ -f /proc/1/cgroup ] && grep -q docker /proc/1/cgroup; then
    echo "⚠️  检测到容器环境"
fi

echo
echo "8. 尝试替代方案:"

# 尝试使用系统Java
echo "检查系统Java:"
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 系统Java可用${NC}"
    java -version
    USE_SYSTEM_JAVA=true
else
    echo "❌ 系统Java不可用"
    USE_SYSTEM_JAVA=false
fi

# 尝试下载不同版本的Java
echo
echo "9. 尝试下载OpenJDK 11 (更兼容):"
JAVA11_URL="https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.20%2B8/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.20_8.tar.gz"
JAVA11_FILE="/data/file-redirect-learning/java-temp/portable-java/openjdk11.tar.gz"
JAVA11_DIR="/data/file-redirect-learning/java-temp/portable-java/jdk11"

if [ ! -f "$JAVA11_FILE" ]; then
    echo "下载OpenJDK 11..."
    if curl -L -k --progress-bar "$JAVA11_URL" -o "$JAVA11_FILE"; then
        echo -e "${GREEN}✅ OpenJDK 11下载成功${NC}"
        
        echo "解压OpenJDK 11..."
        cd /data/file-redirect-learning/java-temp/portable-java/
        if tar -xzf "$JAVA11_FILE"; then
            echo -e "${GREEN}✅ OpenJDK 11解压成功${NC}"
            
            # 查找JDK11目录
            JDK11_ACTUAL=$(find . -maxdepth 1 -type d -name "*jdk*11*" | head -1)
            if [ -n "$JDK11_ACTUAL" ]; then
                JAVA11_BIN="$PWD/$JDK11_ACTUAL/bin/java"
                echo "测试OpenJDK 11: $JAVA11_BIN"
                chmod +x "$JAVA11_BIN"
                
                if "$JAVA11_BIN" -version; then
                    echo -e "${GREEN}✅ OpenJDK 11工作正常！${NC}"
                    export JAVA_HOME="$PWD/$JDK11_ACTUAL"
                    export PATH="$JAVA_HOME/bin:$PATH"
                    USE_JAVA11=true
                else
                    echo -e "${RED}❌ OpenJDK 11也无法工作${NC}"
                    USE_JAVA11=false
                fi
            fi
        fi
    fi
else
    echo "OpenJDK 11文件已存在"
fi

echo
echo "10. 构建决策:"
if [ "$USE_SYSTEM_JAVA" = true ]; then
    echo -e "${GREEN}使用系统Java进行构建${NC}"
elif [ "$USE_JAVA11" = true ]; then
    echo -e "${GREEN}使用OpenJDK 11进行构建${NC}"
else
    echo -e "${RED}❌ 无可用的Java环境${NC}"
    echo
    echo "可能的解决方案:"
    echo "1. 系统可能不支持这个Java版本"
    echo "2. 尝试在不同的终端环境中运行"
    echo "3. 使用Android Studio在电脑上编译"
    echo "4. 检查设备是否支持Java运行时"
    exit 1
fi

echo
echo "11. 开始构建项目:"
cd /data/file-redirect-learning

# 验证Java环境
echo "最终验证Java环境:"
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Java可用${NC}"
    java -version
else
    echo -e "${RED}❌ Java不可用${NC}"
    exit 1
fi

# 设置权限
chmod +x gradlew
chmod +x *.sh

# 构建项目
echo
echo "清理项目..."
if ./gradlew clean; then
    echo -e "${GREEN}✅ 清理成功${NC}"
else
    echo -e "${YELLOW}⚠️  清理失败${NC}"
fi

echo
echo "构建APK..."
if ./gradlew assembleDebug; then
    echo
    echo "================================"
    echo -e "${GREEN}🎉 构建成功！${NC}"
    echo "================================"
    
    # 查找APK
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
        fi
        
        echo
        echo -e "${GREEN}🎉 构建完成！${NC}"
        echo "请安装APK并在Xposed管理器中激活模块。"
    fi
else
    echo -e "${RED}❌ 构建失败${NC}"
    exit 1
fi

echo
echo "脚本执行完成！"
