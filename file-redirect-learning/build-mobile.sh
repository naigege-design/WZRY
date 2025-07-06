#!/bin/bash

# 手机终端专用构建脚本
# 适用于Termux等Android终端环境

echo "================================"
echo "手机终端版 - 文件重定向模块编译"
echo "================================"

# 检查当前目录
echo
echo "步骤1: 检查环境"
echo "当前目录: $(pwd)"

# 列出当前目录文件
echo "当前目录内容:"
ls -la

# 检查必要文件
MISSING_FILES=""

if [ ! -f "gradlew" ]; then
    MISSING_FILES="$MISSING_FILES gradlew"
fi

if [ ! -f "build.gradle" ]; then
    MISSING_FILES="$MISSING_FILES build.gradle"
fi

if [ ! -f "settings.gradle" ]; then
    MISSING_FILES="$MISSING_FILES settings.gradle"
fi

if [ ! -d "xposed-module" ]; then
    MISSING_FILES="$MISSING_FILES xposed-module/"
fi

if [ -n "$MISSING_FILES" ]; then
    echo "❌ 缺少必要文件: $MISSING_FILES"
    echo
    echo "请确保您在正确的项目目录中，并且包含以下文件:"
    echo "  ✓ gradlew"
    echo "  ✓ build.gradle" 
    echo "  ✓ settings.gradle"
    echo "  ✓ xposed-module/ (目录)"
    echo
    echo "如果您刚下载项目，请确保所有文件都已正确提取。"
    exit 1
fi

echo "✅ 项目文件检查通过"

# 设置gradlew权限
echo
echo "步骤2: 设置权限"
chmod +x gradlew
echo "✅ gradlew权限设置完成"

# 检查Java环境
echo
echo "步骤3: 检查Java环境"
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo "✅ Java版本: $JAVA_VERSION"
else
    echo "❌ 未找到Java"
    echo
    echo "在Termux中安装Java:"
    echo "  pkg update"
    echo "  pkg install openjdk-17"
    echo
    echo "然后重新运行此脚本"
    exit 1
fi

# 检查网络连接（Gradle需要下载依赖）
echo
echo "步骤4: 检查网络连接"
if ping -c 1 google.com >/dev/null 2>&1 || ping -c 1 baidu.com >/dev/null 2>&1; then
    echo "✅ 网络连接正常"
else
    echo "⚠️  网络连接可能有问题，但继续尝试构建"
fi

# 清理项目
echo
echo "步骤5: 清理项目"
echo "正在清理..."
./gradlew clean
if [ $? -eq 0 ]; then
    echo "✅ 项目清理完成"
else
    echo "❌ 清理失败，但继续尝试构建"
fi

# 构建项目
echo
echo "步骤6: 构建APK"
echo "正在构建，这可能需要几分钟..."
echo "首次构建会下载依赖，请耐心等待..."

./gradlew assembleDebug

if [ $? -eq 0 ]; then
    echo
    echo "✅ 构建成功！"
    
    # 查找APK文件
    echo
    echo "步骤7: 查找生成的APK"
    APK_FILES=$(find . -name "*.apk" -type f)
    
    if [ -n "$APK_FILES" ]; then
        echo "找到以下APK文件:"
        echo "$APK_FILES"
        
        # 显示APK信息
        for apk in $APK_FILES; do
            echo
            echo "APK文件: $apk"
            echo "文件大小: $(du -h "$apk" | cut -f1)"
            echo "修改时间: $(stat -c %y "$apk" 2>/dev/null || stat -f %Sm "$apk" 2>/dev/null)"
        done
        
        echo
        echo "================================"
        echo "🎉 编译完成！"
        echo "================================"
        echo
        echo "下一步操作:"
        echo "1. 将APK文件传输到目标设备（如果不是同一设备）"
        echo "2. 安装APK: adb install <apk文件路径>"
        echo "3. 在Xposed管理器中激活模块"
        echo "4. 重启设备"
        echo "5. 测试模块效果"
        
    else
        echo "❌ 未找到生成的APK文件"
        echo "请检查构建日志中的错误信息"
    fi
    
else
    echo
    echo "❌ 构建失败"
    echo
    echo "常见问题解决方案:"
    echo "1. 检查网络连接是否正常"
    echo "2. 确保Java版本兼容（推荐Java 8或11）"
    echo "3. 清理项目后重试: ./gradlew clean"
    echo "4. 检查磁盘空间是否充足"
    echo
    echo "如果问题持续，请查看上面的错误日志"
    exit 1
fi

echo
echo "脚本执行完成！"
