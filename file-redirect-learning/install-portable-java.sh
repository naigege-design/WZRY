#!/bin/bash

echo "================================"
echo "便携版Java安装脚本"
echo "适用于Android原生终端环境"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查架构
ARCH=$(uname -m)
echo -e "${BLUE}检测到架构: $ARCH${NC}"

# 设置Java目录
JAVA_DIR="$HOME/portable-java"
echo "Java将安装到: $JAVA_DIR"

# 创建目录
echo
echo "步骤1: 创建Java目录"
mkdir -p "$JAVA_DIR"
cd "$JAVA_DIR"
echo -e "${GREEN}✅ 目录创建完成${NC}"

# 根据架构选择下载链接
echo
echo "步骤2: 下载Java"
case $ARCH in
    "aarch64"|"arm64")
        JAVA_URL="https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-aarch64_bin.tar.gz"
        JAVA_FILE="openjdk-17.0.2_linux-aarch64_bin.tar.gz"
        JAVA_FOLDER="jdk-17.0.2"
        echo -e "${BLUE}使用ARM64版本的Java${NC}"
        ;;
    "x86_64"|"amd64")
        JAVA_URL="https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz"
        JAVA_FILE="openjdk-17.0.2_linux-x64_bin.tar.gz"
        JAVA_FOLDER="jdk-17.0.2"
        echo -e "${BLUE}使用x86_64版本的Java${NC}"
        ;;
    *)
        echo -e "${RED}❌ 不支持的架构: $ARCH${NC}"
        echo "支持的架构: aarch64, arm64, x86_64, amd64"
        exit 1
        ;;
esac

# 检查是否已下载
if [ -f "$JAVA_FILE" ]; then
    echo -e "${YELLOW}Java文件已存在，跳过下载${NC}"
else
    echo "正在下载Java..."
    echo "URL: $JAVA_URL"
    
    # 尝试使用不同的下载工具
    if command -v wget >/dev/null 2>&1; then
        echo "使用wget下载..."
        wget "$JAVA_URL" -O "$JAVA_FILE"
    elif command -v curl >/dev/null 2>&1; then
        echo "使用curl下载..."
        curl -L "$JAVA_URL" -o "$JAVA_FILE"
    else
        echo -e "${RED}❌ 未找到wget或curl，无法下载${NC}"
        echo
        echo "请手动下载Java:"
        echo "1. 在浏览器中打开: $JAVA_URL"
        echo "2. 下载文件到: $JAVA_DIR/$JAVA_FILE"
        echo "3. 然后重新运行此脚本"
        exit 1
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 下载失败${NC}"
        echo
        echo "备用方案:"
        echo "1. 检查网络连接"
        echo "2. 尝试使用移动数据"
        echo "3. 手动下载文件"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Java下载完成${NC}"

# 解压Java
echo
echo "步骤3: 解压Java"
if [ -d "$JAVA_FOLDER" ]; then
    echo -e "${YELLOW}Java已解压，跳过解压步骤${NC}"
else
    echo "正在解压..."
    tar -xzf "$JAVA_FILE"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 解压失败${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Java解压完成${NC}"

# 设置环境变量
echo
echo "步骤4: 设置环境变量"
JAVA_HOME="$JAVA_DIR/$JAVA_FOLDER"

if [ -d "$JAVA_HOME" ]; then
    echo "JAVA_HOME: $JAVA_HOME"
    
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
    
    # 应用环境变量
    export JAVA_HOME="$JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    echo -e "${GREEN}✅ 环境变量设置完成${NC}"
    
    # 验证Java安装
    echo
    echo "步骤5: 验证Java安装"
    if command -v java >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Java安装成功！${NC}"
        java -version
        
        # 创建永久环境变量设置
        echo
        echo "步骤6: 创建永久环境变量"
        BASHRC="$HOME/.bashrc"
        PROFILE="$HOME/.profile"
        
        # 添加到.bashrc
        if ! grep -q "JAVA_HOME.*$JAVA_FOLDER" "$BASHRC" 2>/dev/null; then
            echo "" >> "$BASHRC"
            echo "# Java环境变量 (自动添加)" >> "$BASHRC"
            echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$BASHRC"
            echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> "$BASHRC"
            echo -e "${GREEN}✅ 已添加到 $BASHRC${NC}"
        fi
        
        # 添加到.profile
        if ! grep -q "JAVA_HOME.*$JAVA_FOLDER" "$PROFILE" 2>/dev/null; then
            echo "" >> "$PROFILE"
            echo "# Java环境变量 (自动添加)" >> "$PROFILE"
            echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$PROFILE"
            echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> "$PROFILE"
            echo -e "${GREEN}✅ 已添加到 $PROFILE${NC}"
        fi
        
        echo
        echo "================================"
        echo -e "${GREEN}🎉 Java安装完成！${NC}"
        echo "================================"
        echo
        echo "使用方法:"
        echo "1. 当前会话中Java已可用"
        echo "2. 新会话中运行: source ~/java-env.sh"
        echo "3. 或者重新启动终端"
        echo
        echo "现在可以构建项目了:"
        echo "  ./build-simple.sh"
        
    else
        echo -e "${RED}❌ Java安装验证失败${NC}"
        exit 1
    fi
    
else
    echo -e "${RED}❌ Java目录不存在: $JAVA_HOME${NC}"
    exit 1
fi

echo
echo "脚本执行完成！"
