#!/bin/bash

echo "================================"
echo "使用临时Java构建项目"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 寻找Java环境脚本
find_java_env() {
    local env_scripts=(
        "$(pwd)/java-env.sh"
        "./java-env.sh"
        "/data/local/tmp/portable-java/java-env.sh"
        "./java-temp/portable-java/java-env.sh"
    )
    
    for script in "${env_scripts[@]}"; do
        if [ -f "$script" ]; then
            echo "$script"
            return 0
        fi
    done
    
    return 1
}

# 寻找Java可执行文件
find_java_binary() {
    local java_paths=(
        "$(pwd)/java-temp/portable-java/jdk-*/bin/java"
        "/data/local/tmp/portable-java/jdk-*/bin/java"
        "./portable-java/jdk-*/bin/java"
    )
    
    for java_path in "${java_paths[@]}"; do
        # 使用通配符展开
        for expanded_path in $java_path; do
            if [ -f "$expanded_path" ] && [ -x "$expanded_path" ]; then
                echo "$expanded_path"
                return 0
            fi
        done
    done
    
    return 1
}

echo "步骤1: 查找Java环境"

# 首先检查Java是否已在PATH中
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Java已在PATH中可用${NC}"
    java -version
else
    echo "Java不在PATH中，查找临时安装的Java..."
    
    # 查找环境脚本
    ENV_SCRIPT=$(find_java_env)
    if [ -n "$ENV_SCRIPT" ]; then
        echo -e "${GREEN}✅ 找到Java环境脚本: $ENV_SCRIPT${NC}"
        echo "加载Java环境..."
        source "$ENV_SCRIPT"
    else
        echo "未找到环境脚本，直接查找Java可执行文件..."
        
        JAVA_BIN=$(find_java_binary)
        if [ -n "$JAVA_BIN" ]; then
            echo -e "${GREEN}✅ 找到Java可执行文件: $JAVA_BIN${NC}"
            
            # 设置环境变量
            JAVA_HOME=$(dirname $(dirname "$JAVA_BIN"))
            export JAVA_HOME="$JAVA_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            
            echo "JAVA_HOME: $JAVA_HOME"
            java -version
        else
            echo -e "${RED}❌ 未找到Java${NC}"
            echo
            echo "请先安装Java:"
            echo "  ./install-java-tmp.sh"
            exit 1
        fi
    fi
fi

# 再次验证Java
if ! command -v java >/dev/null 2>&1; then
    echo -e "${RED}❌ Java环境设置失败${NC}"
    exit 1
fi

echo
echo "步骤2: 设置项目权限"
chmod +x gradlew
chmod +x *.sh
echo -e "${GREEN}✅ 权限设置完成${NC}"

echo
echo "步骤3: 清理项目"
if ./gradlew clean; then
    echo -e "${GREEN}✅ 项目清理完成${NC}"
else
    echo -e "${YELLOW}⚠️  清理失败，继续构建...${NC}"
fi

echo
echo "步骤4: 构建APK"
echo "正在构建，请耐心等待..."

if ./gradlew assembleDebug; then
    echo
    echo -e "${GREEN}🎉 构建成功！${NC}"
    
    # 查找APK文件
    echo
    echo "查找生成的APK文件..."
    APK_FILES=$(find . -name "*.apk" -type f 2>/dev/null)
    
    if [ -n "$APK_FILES" ]; then
        echo -e "${GREEN}找到APK文件:${NC}"
        for apk in $APK_FILES; do
            echo "  📱 $apk"
            if [ -f "$apk" ]; then
                size=$(du -h "$apk" 2>/dev/null | cut -f1)
                echo "     大小: $size"
            fi
        done
        
        echo
        echo "================================"
        echo -e "${GREEN}🎉 编译完成！${NC}"
        echo "================================"
        echo
        echo "下一步操作:"
        echo "1. 将APK复制到可访问的位置:"
        echo "   cp $apk /sdcard/Download/"
        echo "2. 安装到已Root的Android设备"
        echo "3. 在Xposed管理器中激活模块"
        echo "4. 重启设备"
        echo "5. 测试模块效果"
        
        # 尝试复制到sdcard
        FIRST_APK=$(echo $APK_FILES | cut -d' ' -f1)
        if [ -w "/sdcard" ] || [ -w "/storage/emulated/0" ]; then
            DEST_DIR="/sdcard"
            [ -w "/storage/emulated/0" ] && DEST_DIR="/storage/emulated/0"
            
            echo
            echo "尝试复制APK到存储卡..."
            if cp "$FIRST_APK" "$DEST_DIR/file-redirect-module.apk"; then
                echo -e "${GREEN}✅ APK已复制到: $DEST_DIR/file-redirect-module.apk${NC}"
            else
                echo -e "${YELLOW}⚠️  无法复制到存储卡${NC}"
            fi
        fi
        
    else
        echo -e "${YELLOW}⚠️  构建成功但未找到APK文件${NC}"
    fi
    
else
    echo
    echo -e "${RED}❌ 构建失败${NC}"
    echo
    echo "可能的原因:"
    echo "1. Java环境问题"
    echo "2. 网络连接问题"
    echo "3. 磁盘空间不足"
    echo "4. 权限问题"
    
    exit 1
fi

echo
echo "脚本执行完成！"
