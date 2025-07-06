#!/bin/bash

echo "================================"
echo "查找系统Java"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "正在搜索系统中的Java..."

# 可能的Java路径
java_paths=(
    "/system/bin/java"
    "/system/xbin/java"
    "/data/local/tmp/java"
    "/vendor/bin/java"
    "/apex/com.android.runtime/bin/java"
    "/apex/com.android.art/bin/java"
    "/system/framework/java"
    "/usr/bin/java"
    "/usr/local/bin/java"
    "/opt/java/bin/java"
)

found_java=false

echo
echo "检查常见Java路径:"
for java_path in "${java_paths[@]}"; do
    if [ -f "$java_path" ] && [ -x "$java_path" ]; then
        echo -e "  ✅ 找到: $java_path"
        echo "     版本信息:"
        "$java_path" -version 2>&1 | head -3 | sed 's/^/        /'
        found_java=true
        
        # 尝试设置环境变量
        export PATH="$(dirname "$java_path"):$PATH"
    else
        echo -e "  ❌ 不存在: $java_path"
    fi
done

echo
echo "搜索整个文件系统中的java可执行文件:"
echo "(这可能需要一些时间...)"

# 搜索java可执行文件
java_files=$(find /system /vendor /apex -name "java" -type f -executable 2>/dev/null | head -10)

if [ -n "$java_files" ]; then
    echo -e "${GREEN}找到以下Java文件:${NC}"
    for java_file in $java_files; do
        echo "  📁 $java_file"
        if [ -x "$java_file" ]; then
            echo "     尝试获取版本信息:"
            timeout 5 "$java_file" -version 2>&1 | head -2 | sed 's/^/        /' || echo "        (无法获取版本信息)"
        fi
    done
    found_java=true
else
    echo -e "${RED}未找到Java文件${NC}"
fi

echo
echo "检查Android Runtime (ART):"
if [ -d "/apex/com.android.art" ]; then
    echo -e "  ✅ 找到ART目录: /apex/com.android.art"
    ls -la /apex/com.android.art/bin/ 2>/dev/null | grep -E "(java|dalvik)" | sed 's/^/     /'
elif [ -d "/apex/com.android.runtime" ]; then
    echo -e "  ✅ 找到Runtime目录: /apex/com.android.runtime"
    ls -la /apex/com.android.runtime/bin/ 2>/dev/null | grep -E "(java|dalvik)" | sed 's/^/     /'
else
    echo -e "  ❌ 未找到Android Runtime目录"
fi

echo
echo "检查环境变量中的Java:"
if command -v java >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Java在PATH中可用${NC}"
    java -version
    found_java=true
else
    echo -e "${RED}❌ Java不在PATH中${NC}"
fi

echo
echo "================================"
if $found_java; then
    echo -e "${GREEN}🎉 找到Java！${NC}"
    echo
    echo "如果Java可用，现在可以尝试构建项目:"
    echo "  ./build-simple.sh"
else
    echo -e "${RED}❌ 未找到可用的Java${NC}"
    echo
    echo "建议安装便携版Java:"
    echo "  ./install-portable-java.sh"
fi
echo "================================"
