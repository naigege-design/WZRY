#!/bin/bash

echo "================================"
echo "简化构建脚本（跳过Java检查）"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "注意: 此脚本假设Java已正确安装"
echo

# 显示Java信息（如果可用）
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 检测到Java:${NC}"
    java -version 2>&1 | head -3 | sed 's/^/   /'
else
    echo -e "${YELLOW}⚠️  未检测到Java，但继续尝试构建...${NC}"
fi

echo
echo "步骤1: 设置权限"
chmod +x gradlew
chmod +x *.sh
echo -e "${GREEN}✅ 权限设置完成${NC}"

echo
echo "步骤2: 清理项目"
if ./gradlew clean; then
    echo -e "${GREEN}✅ 项目清理完成${NC}"
else
    echo -e "${YELLOW}⚠️  清理失败，但继续构建...${NC}"
fi

echo
echo "步骤3: 构建APK"
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
        echo "1. 将APK安装到已Root的Android设备"
        echo "   adb install <apk文件路径>"
        echo "2. 在Xposed管理器中激活模块"
        echo "3. 重启设备"
        echo "4. 测试模块效果"
        
    else
        echo -e "${YELLOW}⚠️  构建成功但未找到APK文件${NC}"
        echo "请检查 xposed-module/build/outputs/apk/ 目录"
    fi
    
else
    echo
    echo -e "${RED}❌ 构建失败${NC}"
    echo
    echo "可能的原因和解决方案:"
    echo "1. Java未正确安装或配置"
    echo "   - 运行: ./manual-java-install.sh"
    echo "2. 网络连接问题"
    echo "   - 检查网络连接"
    echo "   - 尝试使用移动数据或WiFi"
    echo "3. 磁盘空间不足"
    echo "   - 清理不必要的文件"
    echo "4. 权限问题"
    echo "   - 确保有写入权限"
    echo
    echo "调试信息:"
    echo "- 当前目录: $(pwd)"
    echo "- 用户: $(whoami)"
    echo "- 可用空间: $(df -h . 2>/dev/null | tail -1 | awk '{print $4}' || echo '未知')"
    
    exit 1
fi

echo
echo "脚本执行完成！"
