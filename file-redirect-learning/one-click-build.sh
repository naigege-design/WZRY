#!/bin/bash

echo "================================"
echo "一键安装Java并构建项目"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查Java是否已可用
check_java() {
    if command -v java >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Java已可用${NC}"
        java -version
        return 0
    else
        return 1
    fi
}

# 尝试加载已安装的Java
load_java_env() {
    if [ -f "$HOME/java-env.sh" ]; then
        echo "加载Java环境..."
        source "$HOME/java-env.sh"
        return 0
    fi
    return 1
}

echo "步骤1: 检查Java环境"
if check_java; then
    echo "Java已可用，跳过安装"
elif load_java_env && check_java; then
    echo "Java环境加载成功"
else
    echo -e "${YELLOW}需要安装Java${NC}"
    
    echo
    echo "步骤2: 修复Java安装"
    chmod +x fix-java-install.sh
    ./fix-java-install.sh
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Java安装失败${NC}"
        exit 1
    fi
    
    # 重新加载环境
    if [ -f "$HOME/java-env.sh" ]; then
        source "$HOME/java-env.sh"
    fi
    
    if ! check_java; then
        echo -e "${RED}❌ Java安装后仍不可用${NC}"
        exit 1
    fi
fi

echo
echo "步骤3: 构建项目"
chmod +x build-simple.sh
./build-simple.sh

if [ $? -eq 0 ]; then
    echo
    echo "================================"
    echo -e "${GREEN}🎉 构建完成！${NC}"
    echo "================================"
    
    # 查找APK文件
    APK_FILES=$(find . -name "*.apk" -type f 2>/dev/null)
    if [ -n "$APK_FILES" ]; then
        echo
        echo "生成的APK文件:"
        for apk in $APK_FILES; do
            echo "  📱 $apk"
        done
        
        echo
        echo "下一步操作:"
        echo "1. 将APK安装到已Root的Android设备"
        echo "2. 在Xposed管理器中激活模块"
        echo "3. 重启设备"
        echo "4. 测试模块效果"
    fi
else
    echo -e "${RED}❌ 构建失败${NC}"
    exit 1
fi

echo
echo "脚本执行完成！"
