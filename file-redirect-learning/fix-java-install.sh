#!/bin/bash

echo "================================"
echo "Java安装修复脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

JAVA_DIR="$HOME/portable-java"
ARCH=$(uname -m)

echo -e "${BLUE}架构: $ARCH${NC}"
echo -e "${BLUE}Java目录: $JAVA_DIR${NC}"

# 步骤1: 创建目录
echo
echo "步骤1: 确保Java目录存在"
if [ ! -d "$JAVA_DIR" ]; then
    echo "创建Java目录..."
    mkdir -p "$JAVA_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Java目录创建成功${NC}"
    else
        echo -e "${RED}❌ Java目录创建失败${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Java目录已存在${NC}"
fi

cd "$JAVA_DIR"

# 步骤2: 检查现有文件
echo
echo "步骤2: 检查现有文件"
echo "当前目录内容:"
ls -la

# 根据架构设置下载信息
case $ARCH in
    "aarch64"|"arm64")
        JAVA_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.8.1_1.tar.gz"
        JAVA_FILE="OpenJDK17U-jdk_aarch64_linux_hotspot_17.0.8.1_1.tar.gz"
        JAVA_FOLDER="jdk-17.0.8.1+1"
        echo -e "${BLUE}使用ARM64版本的Java${NC}"
        ;;
    "x86_64"|"amd64")
        JAVA_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1%2B1/OpenJDK17U-jdk_x64_linux_hotspot_17.0.8.1_1.tar.gz"
        JAVA_FILE="OpenJDK17U-jdk_x64_linux_hotspot_17.0.8.1_1.tar.gz"
        JAVA_FOLDER="jdk-17.0.8.1+1"
        echo -e "${BLUE}使用x86_64版本的Java${NC}"
        ;;
    *)
        echo -e "${RED}❌ 不支持的架构: $ARCH${NC}"
        exit 1
        ;;
esac

# 步骤3: 下载Java（如果需要）
echo
echo "步骤3: 下载Java"
if [ -f "$JAVA_FILE" ]; then
    echo -e "${YELLOW}Java文件已存在，跳过下载${NC}"
else
    echo "正在下载Java..."
    echo "URL: $JAVA_URL"
    
    # 尝试下载
    download_success=false
    
    if command -v wget >/dev/null 2>&1; then
        echo "使用wget下载..."
        wget --no-check-certificate "$JAVA_URL" -O "$JAVA_FILE"
        if [ $? -eq 0 ]; then
            download_success=true
        fi
    fi
    
    if ! $download_success && command -v curl >/dev/null 2>&1; then
        echo "使用curl下载..."
        curl -L -k "$JAVA_URL" -o "$JAVA_FILE"
        if [ $? -eq 0 ]; then
            download_success=true
        fi
    fi
    
    if ! $download_success; then
        echo -e "${RED}❌ 下载失败${NC}"
        echo
        echo "手动下载方法:"
        echo "1. 在浏览器中打开: $JAVA_URL"
        echo "2. 下载文件并重命名为: $JAVA_FILE"
        echo "3. 将文件放到: $JAVA_DIR/"
        echo "4. 重新运行此脚本"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Java下载完成${NC}"
fi

# 检查文件大小
if [ -f "$JAVA_FILE" ]; then
    FILE_SIZE=$(du -h "$JAVA_FILE" | cut -f1)
    echo "文件大小: $FILE_SIZE"
    
    # 检查文件是否完整（至少应该有几十MB）
    FILE_SIZE_BYTES=$(stat -c%s "$JAVA_FILE" 2>/dev/null || stat -f%z "$JAVA_FILE" 2>/dev/null)
    if [ "$FILE_SIZE_BYTES" -lt 50000000 ]; then  # 50MB
        echo -e "${YELLOW}⚠️  文件可能不完整，重新下载...${NC}"
        rm -f "$JAVA_FILE"
        # 重新下载的逻辑可以在这里添加
    fi
fi

# 步骤4: 解压Java
echo
echo "步骤4: 解压Java"
if [ -d "$JAVA_FOLDER" ]; then
    echo -e "${YELLOW}Java已解压，跳过解压步骤${NC}"
else
    if [ -f "$JAVA_FILE" ]; then
        echo "正在解压..."
        tar -xzf "$JAVA_FILE"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Java解压完成${NC}"
        else
            echo -e "${RED}❌ 解压失败${NC}"
            echo "尝试手动解压:"
            echo "  cd $JAVA_DIR"
            echo "  tar -xzf $JAVA_FILE"
            exit 1
        fi
    else
        echo -e "${RED}❌ Java文件不存在，无法解压${NC}"
        exit 1
    fi
fi

# 步骤5: 验证Java
echo
echo "步骤5: 验证Java安装"
JAVA_HOME="$JAVA_DIR/$JAVA_FOLDER"
JAVA_BIN="$JAVA_HOME/bin/java"

echo "JAVA_HOME: $JAVA_HOME"
echo "Java可执行文件: $JAVA_BIN"

if [ -f "$JAVA_BIN" ] && [ -x "$JAVA_BIN" ]; then
    echo -e "${GREEN}✅ Java可执行文件存在${NC}"
    
    # 测试Java
    echo "测试Java..."
    "$JAVA_BIN" -version
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Java工作正常${NC}"
        
        # 设置环境变量
        export JAVA_HOME="$JAVA_HOME"
        export PATH="$JAVA_HOME/bin:$PATH"
        
        # 创建环境变量脚本
        ENV_SCRIPT="$HOME/java-env.sh"
        cat > "$ENV_SCRIPT" << EOF
#!/bin/bash
# Java环境变量设置
export JAVA_HOME="$JAVA_HOME"
export PATH="\$JAVA_HOME/bin:\$PATH"
echo "Java环境已设置"
echo "JAVA_HOME: \$JAVA_HOME"
java -version
EOF
        chmod +x "$ENV_SCRIPT"
        
        echo -e "${GREEN}✅ 环境变量脚本已创建: $ENV_SCRIPT${NC}"
        
        echo
        echo "================================"
        echo -e "${GREEN}🎉 Java修复完成！${NC}"
        echo "================================"
        echo
        echo "使用方法:"
        echo "1. 加载环境变量: source ~/java-env.sh"
        echo "2. 构建项目: ./build-simple.sh"
        echo
        echo "或者直接运行:"
        echo "  source ~/java-env.sh && ./build-simple.sh"
        
    else
        echo -e "${RED}❌ Java无法正常工作${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Java可执行文件不存在或无执行权限${NC}"
    echo "检查目录结构:"
    find "$JAVA_HOME" -name "java" -type f 2>/dev/null | head -5
    exit 1
fi

echo
echo "脚本执行完成！"
