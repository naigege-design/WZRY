#!/bin/bash

echo "================================"
echo "自动安装Java并构建项目"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检测环境类型
detect_environment() {
    if command -v pkg >/dev/null 2>&1; then
        echo "termux"
    elif command -v apt >/dev/null 2>&1; then
        echo "debian"
    elif command -v yum >/dev/null 2>&1; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

ENV_TYPE=$(detect_environment)

echo -e "${BLUE}检测到环境类型: $ENV_TYPE${NC}"
echo

# 检查Java是否已安装
check_java() {
    if command -v java >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1)
        echo -e "${GREEN}✅ Java已安装: $JAVA_VERSION${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Java未安装${NC}"
        return 1
    fi
}

# 安装Java
install_java() {
    echo -e "${YELLOW}正在安装Java...${NC}"
    
    case $ENV_TYPE in
        "termux")
            echo "在Termux环境中安装Java..."
            pkg update
            echo "尝试安装OpenJDK 17..."
            if pkg install openjdk-17; then
                echo -e "${GREEN}✅ OpenJDK 17安装成功${NC}"
            else
                echo -e "${YELLOW}OpenJDK 17安装失败，尝试OpenJDK 11...${NC}"
                if pkg install openjdk-11; then
                    echo -e "${GREEN}✅ OpenJDK 11安装成功${NC}"
                else
                    echo -e "${YELLOW}OpenJDK 11安装失败，尝试OpenJDK 8...${NC}"
                    if pkg install openjdk-8; then
                        echo -e "${GREEN}✅ OpenJDK 8安装成功${NC}"
                    else
                        echo -e "${RED}❌ 所有Java版本安装失败${NC}"
                        return 1
                    fi
                fi
            fi
            ;;
        "debian")
            echo "在Debian/Ubuntu环境中安装Java..."
            sudo apt update
            if sudo apt install -y openjdk-17-jdk; then
                echo -e "${GREEN}✅ OpenJDK 17安装成功${NC}"
            else
                echo -e "${YELLOW}尝试安装默认JDK...${NC}"
                if sudo apt install -y default-jdk; then
                    echo -e "${GREEN}✅ 默认JDK安装成功${NC}"
                else
                    echo -e "${RED}❌ Java安装失败${NC}"
                    return 1
                fi
            fi
            ;;
        *)
            echo -e "${RED}❌ 不支持的环境，请手动安装Java${NC}"
            echo
            echo "手动安装方法:"
            echo "Termux: pkg install openjdk-17"
            echo "Ubuntu/Debian: sudo apt install openjdk-17-jdk"
            echo "CentOS/RHEL: sudo yum install java-17-openjdk-devel"
            return 1
            ;;
    esac
}

# 主流程
echo "步骤1: 检查Java环境"
if ! check_java; then
    echo
    echo "步骤2: 安装Java"
    if ! install_java; then
        echo -e "${RED}Java安装失败，无法继续构建${NC}"
        exit 1
    fi
    
    # 重新检查Java
    echo
    echo "步骤3: 验证Java安装"
    if ! check_java; then
        echo -e "${RED}Java安装验证失败${NC}"
        exit 1
    fi
else
    echo "Java已安装，跳过安装步骤"
fi

echo
echo "步骤4: 设置环境"
# 设置权限
chmod +x gradlew
chmod +x *.sh

echo -e "${GREEN}✅ 环境设置完成${NC}"

echo
echo "步骤5: 开始构建项目"
echo "这可能需要几分钟时间，请耐心等待..."

# 清理项目
echo "清理项目..."
./gradlew clean

# 构建项目
echo "构建APK..."
./gradlew assembleDebug

if [ $? -eq 0 ]; then
    echo
    echo -e "${GREEN}🎉 构建成功！${NC}"
    
    # 查找APK
    APK_FILES=$(find . -name "*.apk" -type f)
    if [ -n "$APK_FILES" ]; then
        echo
        echo "生成的APK文件:"
        for apk in $APK_FILES; do
            echo "  📱 $apk"
            echo "     大小: $(du -h "$apk" | cut -f1)"
        done
        
        echo
        echo "================================"
        echo "🎉 编译完成！"
        echo "================================"
        echo
        echo "下一步操作:"
        echo "1. 安装APK到目标设备"
        echo "2. 在Xposed管理器中激活模块"
        echo "3. 重启设备"
        echo "4. 测试模块效果"
    else
        echo -e "${YELLOW}⚠️  构建成功但未找到APK文件${NC}"
    fi
else
    echo
    echo -e "${RED}❌ 构建失败${NC}"
    echo
    echo "可能的解决方案:"
    echo "1. 检查网络连接"
    echo "2. 清理项目: ./gradlew clean"
    echo "3. 检查磁盘空间"
    echo "4. 重新运行此脚本"
fi

echo
echo "脚本执行完成！"
