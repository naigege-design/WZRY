#!/bin/bash

echo "================================"
echo "完整构建解决方案"
echo "适用于受限Android环境"
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

echo
echo "步骤1: 检查Java环境"
if check_java; then
    echo "Java已可用，跳过安装"
else
    echo -e "${YELLOW}需要安装Java${NC}"
    
    echo
    echo "步骤2: 安装临时Java"
    chmod +x install-java-tmp.sh
    ./install-java-tmp.sh
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Java安装失败${NC}"
        echo
        echo "手动解决方案:"
        echo "1. 检查是否有root权限: su"
        echo "2. 切换到可写目录: cd /data/local/tmp"
        echo "3. 重新运行脚本"
        exit 1
    fi
    
    # 重新检查Java
    if ! check_java; then
        echo -e "${YELLOW}尝试加载Java环境...${NC}"
        
        # 查找并加载Java环境
        for env_script in "$(pwd)/java-env.sh" "./java-temp/portable-java/java-env.sh"; do
            if [ -f "$env_script" ]; then
                echo "加载: $env_script"
                source "$env_script"
                break
            fi
        done
        
        if ! check_java; then
            echo -e "${RED}❌ Java环境设置失败${NC}"
            exit 1
        fi
    fi
fi

echo
echo "步骤3: 构建项目"
chmod +x build-with-temp-java.sh
./build-with-temp-java.sh

if [ $? -eq 0 ]; then
    echo
    echo "================================"
    echo -e "${GREEN}🎉 完整构建成功！${NC}"
    echo "================================"
    
    # 显示结果摘要
    APK_FILES=$(find . -name "*.apk" -type f 2>/dev/null)
    if [ -n "$APK_FILES" ]; then
        echo
        echo -e "${GREEN}生成的APK文件:${NC}"
        for apk in $APK_FILES; do
            echo "  📱 $apk"
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
    fi
else
    echo -e "${RED}❌ 构建失败${NC}"
    exit 1
fi

echo
echo "脚本执行完成！"
