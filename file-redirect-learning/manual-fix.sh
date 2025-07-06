#!/bin/bash

echo "================================"
echo "手动修复Java环境"
echo "================================"

# 直接设置已知的Java路径
JAVA_HOME="/data/file-redirect-learning/java-temp/portable-java/jdk-17.0.8.1+1"
export JAVA_HOME="$JAVA_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

echo "设置Java环境变量:"
echo "JAVA_HOME: $JAVA_HOME"
echo "PATH: $PATH"

echo
echo "验证Java安装:"
if [ -f "$JAVA_HOME/bin/java" ]; then
    echo "✅ Java文件存在"
    
    # 设置执行权限
    chmod +x "$JAVA_HOME/bin/java"
    
    # 测试Java
    if "$JAVA_HOME/bin/java" -version; then
        echo "✅ Java工作正常"
    else
        echo "❌ Java测试失败"
        exit 1
    fi
else
    echo "❌ Java文件不存在"
    echo "查找Java文件:"
    find /data/file-redirect-learning/java-temp -name "java" -type f 2>/dev/null
    exit 1
fi

echo
echo "开始构建项目..."

# 确保在项目目录
cd /data/file-redirect-learning

# 设置权限
chmod +x gradlew

echo "清理项目..."
./gradlew clean

echo "构建APK..."
./gradlew assembleDebug

if [ $? -eq 0 ]; then
    echo
    echo "🎉 构建成功！"
    
    # 查找APK
    find . -name "*.apk" -type f 2>/dev/null | while read apk; do
        echo "📱 生成的APK: $apk"
        size=$(du -h "$apk" | cut -f1)
        echo "   大小: $size"
        
        # 复制到存储卡
        if [ -w "/sdcard" ]; then
            cp "$apk" "/sdcard/file-redirect-module.apk"
            echo "✅ APK已复制到: /sdcard/file-redirect-module.apk"
        fi
    done
    
    echo
    echo "构建完成！请安装APK并在Xposed中激活模块。"
else
    echo "❌ 构建失败"
fi
