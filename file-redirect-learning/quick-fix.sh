#!/bin/bash

echo "================================"
echo "快速修复脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "当前目录: $(pwd)"

# 直接使用已存在的Java
JAVA_DIR="/data/file-redirect-learning/java-temp/portable-java"
JDK_FOLDER="jdk-17.0.8.1+1"

echo "检查Java安装..."
echo "Java目录: $JAVA_DIR"
echo "JDK文件夹: $JDK_FOLDER"

if [ -d "$JAVA_DIR/$JDK_FOLDER" ]; then
    echo -e "${GREEN}✅ JDK目录存在${NC}"
    
    JAVA_HOME="$JAVA_DIR/$JDK_FOLDER"
    JAVA_BIN="$JAVA_HOME/bin/java"
    
    echo "JAVA_HOME: $JAVA_HOME"
    echo "Java可执行文件: $JAVA_BIN"
    
    if [ -f "$JAVA_BIN" ]; then
        echo -e "${GREEN}✅ Java文件存在${NC}"
        
        # 设置执行权限
        chmod +x "$JAVA_BIN"
        
        # 测试Java
        echo "测试Java..."
        if "$JAVA_BIN" -version; then
            echo -e "${GREEN}✅ Java工作正常${NC}"
            
            # 设置环境变量
            export JAVA_HOME="$JAVA_HOME"
            export PATH="$JAVA_HOME/bin:$PATH"
            
            echo -e "${GREEN}✅ Java环境已设置${NC}"
            echo "JAVA_HOME: $JAVA_HOME"
            echo "PATH: $PATH"
            
        else
            echo -e "${RED}❌ Java测试失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Java文件不存在: $JAVA_BIN${NC}"
        echo "查找java文件:"
        find "$JAVA_HOME" -name "java" -type f 2>/dev/null
        exit 1
    fi
else
    echo -e "${RED}❌ JDK目录不存在: $JAVA_DIR/$JDK_FOLDER${NC}"
    echo "查找可能的JDK目录:"
    find "$JAVA_DIR" -maxdepth 2 -type d -name "*jdk*" 2>/dev/null
    exit 1
fi

echo
echo "步骤2: 构建项目"
echo "当前目录: $(pwd)"

# 确保在正确的项目目录
cd /data/file-redirect-learning

# 设置权限
chmod +x gradlew
chmod +x *.sh

# 验证Java环境
echo "验证Java环境..."
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Java在PATH中可用${NC}"
    java -version
else
    echo -e "${RED}❌ Java不在PATH中${NC}"
    exit 1
fi

# 清理项目
echo
echo "清理项目..."
if ./gradlew clean; then
    echo -e "${GREEN}✅ 项目清理完成${NC}"
else
    echo -e "${YELLOW}⚠️  清理失败，继续构建...${NC}"
fi

# 构建APK
echo
echo "构建APK..."
if ./gradlew assembleDebug; then
    echo
    echo "================================"
    echo -e "${GREEN}🎉 构建完成！${NC}"
    echo "================================"
    
    # 查找APK文件
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
            cp "$FIRST_APK" "/sdcard/file-redirect-module.apk" 2>/dev/null && \
            echo -e "${GREEN}✅ APK已复制到: /sdcard/file-redirect-module.apk${NC}"
        elif [ -w "/storage/emulated/0" ]; then
            cp "$FIRST_APK" "/storage/emulated/0/file-redirect-module.apk" 2>/dev/null && \
            echo -e "${GREEN}✅ APK已复制到: /storage/emulated/0/file-redirect-module.apk${NC}"
        fi
        
        echo
        echo -e "${GREEN}🎉 构建成功完成！${NC}"
        echo
        echo -e "${YELLOW}下一步操作:${NC}"
        echo "1. 安装APK到已Root的Android设备"
        echo "2. 打开Xposed管理器 (LSPosed/EdXposed)"
        echo "3. 激活'文件重定向模块'"
        echo "4. 选择作用域 (目标应用)"
        echo "5. 重启设备"
        echo "6. 测试模块效果"
        
        echo
        echo -e "${YELLOW}⚠️  重要提醒:${NC}"
        echo "• 仅用于学习目的"
        echo "• 需要Root权限和Xposed框架"
        echo "• 请勿用于非法用途"
        
    else
        echo -e "${YELLOW}⚠️  构建成功但未找到APK文件${NC}"
    fi
else
    echo -e "${RED}❌ 构建失败${NC}"
    echo
    echo "可能的问题:"
    echo "1. Java环境问题"
    echo "2. 网络连接问题"
    echo "3. 磁盘空间不足"
    exit 1
fi

echo
echo "脚本执行完成！"
