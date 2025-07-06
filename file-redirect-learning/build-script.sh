#!/bin/bash

echo "================================"
echo "文件重定向模块自动编译脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo
echo -e "${YELLOW}[1/4] 检查环境...${NC}"

# 检查当前目录
echo "当前目录: $(pwd)"
echo "目录内容:"
ls -la

# 检查gradlew是否存在
if [ ! -f "./gradlew" ]; then
    echo -e "${RED}❌ 未找到gradlew文件${NC}"
    echo "请确保您在 file-redirect-learning 目录中运行此脚本"
    echo "目录结构应该包含:"
    echo "  - gradlew (Linux/Mac版本)"
    echo "  - gradlew.bat (Windows版本)"
    echo "  - build.gradle"
    echo "  - settings.gradle"
    exit 1
fi

# 给gradlew执行权限
chmod +x ./gradlew

# 检查Java环境
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "Java版本: $JAVA_VERSION"
else
    echo -e "${RED}❌ 未找到Java，请先安装Java JDK${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Gradle环境正常${NC}"

echo
echo -e "${YELLOW}[2/4] 清理项目...${NC}"
./gradlew clean
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 清理失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 项目清理完成${NC}"

echo
echo -e "${YELLOW}[3/4] 编译APK...${NC}"
./gradlew assembleDebug
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 编译失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 编译成功${NC}"

echo
echo -e "${YELLOW}[4/4] 查找生成的APK...${NC}"

# 查找APK文件
APK_PATH=$(find . -name "*.apk" -type f | head -1)

if [ -n "$APK_PATH" ]; then
    echo
    echo "================================"
    echo -e "${GREEN}✅ 编译完成！${NC}"
    echo "APK位置: $APK_PATH"
    echo "================================"
    echo
    echo "下一步操作:"
    echo "1. 将APK安装到已Root的Android设备"
    echo "2. 在Xposed管理器中激活模块"
    echo "3. 重启设备"
    echo "4. 测试模块效果"
    echo
    
    # 检查是否有设备连接
    if command -v adb &> /dev/null; then
        DEVICE_COUNT=$(adb devices | grep -c "device$")
        if [ $DEVICE_COUNT -gt 0 ]; then
            echo -e "${YELLOW}检测到已连接的Android设备${NC}"
            echo -n "是否要自动安装到设备？(y/n): "
            read -r choice
            if [[ $choice == "y" || $choice == "Y" ]]; then
                echo "正在安装..."
                adb install "$APK_PATH"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ 安装成功！${NC}"
                    echo
                    echo "请在Xposed管理器中激活模块并重启设备"
                else
                    echo -e "${RED}❌ 安装失败，请手动安装${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}未检测到连接的设备，请手动安装APK${NC}"
        fi
    else
        echo -e "${YELLOW}未安装ADB，请手动安装APK${NC}"
    fi
else
    echo -e "${RED}❌ 未找到生成的APK文件${NC}"
    exit 1
fi

echo
echo -e "${GREEN}脚本执行完成！${NC}"
