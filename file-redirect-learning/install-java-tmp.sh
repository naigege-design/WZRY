#!/bin/bash

echo "================================"
echo "临时目录Java安装脚本"
echo "适用于受限Android环境"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 寻找可写目录
find_writable_dir() {
    local test_dirs=(
        "/data/local/tmp"
        "/sdcard"
        "/storage/emulated/0"
        "/tmp"
        "/var/tmp"
        "$(pwd)/temp"
        "."
    )
    
    for dir in "${test_dirs[@]}"; do
        if [ -d "$dir" ] && [ -w "$dir" ]; then
            echo "$dir"
            return 0
        fi
    done
    
    return 1
}

echo "步骤1: 寻找可写目录"
WORK_DIR=$(find_writable_dir)

if [ -z "$WORK_DIR" ]; then
    echo -e "${RED}❌ 未找到可写目录${NC}"
    echo
    echo "尝试创建临时目录:"
    mkdir -p "./java-temp" 2>/dev/null
    if [ -w "./java-temp" ]; then
        WORK_DIR="$(pwd)/java-temp"
        echo -e "${GREEN}✅ 创建临时目录成功: $WORK_DIR${NC}"
    else
        echo -e "${RED}❌ 无法创建可写目录${NC}"
        echo "请尝试以下方法:"
        echo "1. 使用su获取root权限"
        echo "2. 切换到/data/local/tmp目录"
        echo "3. 使用Termux等用户级终端"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 找到可写目录: $WORK_DIR${NC}"
fi

# 设置Java目录
JAVA_DIR="$WORK_DIR/portable-java"
echo "Java将安装到: $JAVA_DIR"

echo
echo "步骤2: 创建Java目录"
mkdir -p "$JAVA_DIR"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Java目录创建成功${NC}"
else
    echo -e "${RED}❌ Java目录创建失败${NC}"
    exit 1
fi

cd "$JAVA_DIR"

# 检测架构
ARCH=$(uname -m)
echo -e "${BLUE}检测到架构: $ARCH${NC}"

# 设置下载信息
case $ARCH in
    "aarch64"|"arm64")
        JAVA_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.8.1_1.tar.gz"
        JAVA_FILE="OpenJDK17U-jdk_aarch64_linux.tar.gz"
        JAVA_FOLDER="jdk-17.0.8.1+1"
        ;;
    "x86_64"|"amd64")
        JAVA_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_x64_linux_hotspot_17.0.8.1_1.tar.gz"
        JAVA_FILE="OpenJDK17U-jdk_x64_linux.tar.gz"
        JAVA_FOLDER="jdk-17.0.8.1+1"
        ;;
    *)
        echo -e "${RED}❌ 不支持的架构: $ARCH${NC}"
        exit 1
        ;;
esac

echo
echo "步骤3: 下载Java"
echo "URL: $JAVA_URL"

if [ -f "$JAVA_FILE" ]; then
    echo -e "${YELLOW}Java文件已存在，跳过下载${NC}"
else
    echo "正在下载Java (这可能需要几分钟)..."
    
    if curl -L -k --progress-bar "$JAVA_URL" -o "$JAVA_FILE"; then
        echo -e "${GREEN}✅ Java下载完成${NC}"
    else
        echo -e "${RED}❌ 下载失败${NC}"
        echo
        echo "备用下载方法:"
        echo "1. 手动下载: $JAVA_URL"
        echo "2. 保存为: $JAVA_DIR/$JAVA_FILE"
        echo "3. 重新运行此脚本"
        exit 1
    fi
fi

# 检查文件大小
FILE_SIZE=$(du -h "$JAVA_FILE" | cut -f1)
echo "下载文件大小: $FILE_SIZE"

echo
echo "步骤4: 解压Java"
if [ -d "$JAVA_FOLDER" ]; then
    echo -e "${YELLOW}Java已解压，跳过解压${NC}"
else
    echo "正在解压..."
    if tar -xzf "$JAVA_FILE"; then
        echo -e "${GREEN}✅ Java解压完成${NC}"
    else
        echo -e "${RED}❌ 解压失败${NC}"
        exit 1
    fi
fi

echo
echo "步骤5: 验证Java"
JAVA_HOME="$JAVA_DIR/$JAVA_FOLDER"
JAVA_BIN="$JAVA_HOME/bin/java"

if [ -f "$JAVA_BIN" ] && [ -x "$JAVA_BIN" ]; then
    echo -e "${GREEN}✅ Java可执行文件存在${NC}"
    
    # 测试Java
    echo "测试Java..."
    "$JAVA_BIN" -version
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Java工作正常${NC}"
        
        # 设置当前会话的环境变量
        export JAVA_HOME="$JAVA_HOME"
        export PATH="$JAVA_HOME/bin:$PATH"
        
        # 创建环境变量脚本（在当前目录）
        ENV_SCRIPT="$(pwd)/java-env.sh"
        cat > "$ENV_SCRIPT" << EOF
#!/bin/bash
# Java环境变量设置 (临时安装)
export JAVA_HOME="$JAVA_HOME"
export PATH="\$JAVA_HOME/bin:\$PATH"
echo "Java环境已设置 (临时安装)"
echo "JAVA_HOME: \$JAVA_HOME"
java -version
EOF
        chmod +x "$ENV_SCRIPT"
        
        echo -e "${GREEN}✅ 环境变量脚本已创建: $ENV_SCRIPT${NC}"
        
        echo
        echo "================================"
        echo -e "${GREEN}🎉 Java安装完成！${NC}"
        echo "================================"
        echo
        echo "Java安装位置: $JAVA_HOME"
        echo "环境脚本: $ENV_SCRIPT"
        echo
        echo "现在可以构建项目了:"
        echo "  source $ENV_SCRIPT"
        echo "  ./build-simple.sh"
        echo
        echo "或者直接运行:"
        echo "  ./build-with-temp-java.sh"
        
    else
        echo -e "${RED}❌ Java无法正常工作${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Java可执行文件不存在${NC}"
    exit 1
fi

echo
echo "脚本执行完成！"
