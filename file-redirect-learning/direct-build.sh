#!/bin/bash

echo "================================"
echo "直接构建脚本"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "当前目录: $(pwd)"

# 直接设置正确的Java路径
JAVA_HOME="/data/file-redirect-learning/java-temp/portable-java/jdk-17.0.8.1+1"
JAVA_BIN="$JAVA_HOME/bin/java"

echo "设置Java环境:"
echo "JAVA_HOME: $JAVA_HOME"
echo "Java可执行文件: $JAVA_BIN"

# 检查Java是否存在
if [ -f "$JAVA_BIN" ]; then
    echo -e "${GREEN}✅ Java文件存在${NC}"
    
    # 设置执行权限
    chmod +x "$JAVA_BIN"
    chmod +x "$JAVA_HOME/bin/"*
    
    # 设置环境变量
    export JAVA_HOME="$JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
    
    # 测试Java
    echo "测试Java..."
    if "$JAVA_BIN" -version; then
        echo -e "${GREEN}✅ Java工作正常${NC}"
    else
        echo -e "${RED}❌ Java测试失败${NC}"
        
        # 尝试诊断问题
        echo "诊断信息:"
        echo "文件权限: $(ls -la "$JAVA_BIN")"
        echo "文件类型: $(file "$JAVA_BIN" 2>/dev/null || echo '无法检测')"
        
        # 尝试直接执行
        echo "尝试直接执行:"
        "$JAVA_BIN" -version 2>&1 || echo "直接执行失败"
        
        exit 1
    fi
else
    echo -e "${RED}❌ Java文件不存在: $JAVA_BIN${NC}"
    
    # 查找实际的Java文件
    echo "查找Java文件:"
    find /data/file-redirect-learning/java-temp -name "java" -type f 2>/dev/null
    
    # 显示目录结构
    echo "Java目录结构:"
    if [ -d "/data/file-redirect-learning/java-temp/portable-java" ]; then
        ls -la /data/file-redirect-learning/java-temp/portable-java/
        if [ -d "/data/file-redirect-learning/java-temp/portable-java/jdk-17.0.8.1+1" ]; then
            echo "JDK目录内容:"
            ls -la /data/file-redirect-learning/java-temp/portable-java/jdk-17.0.8.1+1/
        fi
    fi
    
    exit 1
fi

echo
echo "步骤2: 构建项目"

# 确保在项目根目录
cd /data/file-redirect-learning

# 验证当前Java环境
echo "验证Java环境:"
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Java在PATH中可用${NC}"
    java -version
else
    echo -e "${RED}❌ Java不在PATH中${NC}"
    exit 1
fi

# 设置项目权限
chmod +x gradlew
chmod +x *.sh

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
echo "构建APK (这可能需要几分钟)..."
if ./gradlew assembleDebug; then
    echo
    echo "================================"
    echo -e "${GREEN}🎉 构建成功！${NC}"
    echo "================================"
    
    # 查找APK文件
    echo "查找生成的APK文件..."
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
        echo
        echo "复制APK到存储卡..."
        
        if [ -w "/sdcard" ]; then
            if cp "$FIRST_APK" "/sdcard/file-redirect-module.apk"; then
                echo -e "${GREEN}✅ APK已复制到: /sdcard/file-redirect-module.apk${NC}"
            else
                echo -e "${YELLOW}⚠️  复制到/sdcard失败${NC}"
            fi
        elif [ -w "/storage/emulated/0" ]; then
            if cp "$FIRST_APK" "/storage/emulated/0/file-redirect-module.apk"; then
                echo -e "${GREEN}✅ APK已复制到: /storage/emulated/0/file-redirect-module.apk${NC}"
            else
                echo -e "${YELLOW}⚠️  复制到/storage/emulated/0失败${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  无法找到可写的存储目录${NC}"
        fi
        
        echo
        echo "================================"
        echo -e "${GREEN}🎉 构建完成！${NC}"
        echo "================================"
        echo
        echo -e "${YELLOW}使用说明:${NC}"
        echo "1. 将APK安装到已Root的Android设备"
        echo "   adb install $FIRST_APK"
        echo "2. 打开Xposed管理器 (LSPosed/EdXposed)"
        echo "3. 在模块列表中找到'文件重定向模块'"
        echo "4. 勾选激活该模块"
        echo "5. 选择作用域 (目标应用，如王者荣耀)"
        echo "6. 重启设备"
        echo "7. 测试模块效果"
        echo
        echo -e "${YELLOW}⚠️  重要提醒:${NC}"
        echo "• 仅用于学习目的"
        echo "• 需要Root权限和Xposed框架"
        echo "• 请勿用于非法用途"
        echo "• 使用前请备份重要数据"
        
    else
        echo -e "${YELLOW}⚠️  构建成功但未找到APK文件${NC}"
        echo "请检查构建输出目录:"
        find . -name "build" -type d 2>/dev/null | head -5
    fi
    
else
    echo
    echo -e "${RED}❌ 构建失败${NC}"
    echo
    echo "可能的问题:"
    echo "1. Java环境问题 - 重新运行脚本"
    echo "2. 网络连接问题 - 检查网络"
    echo "3. 磁盘空间不足 - 清理空间"
    echo "4. 权限问题 - 检查文件权限"
    
    exit 1
fi

echo
echo "脚本执行完成！"
