#!/bin/bash

echo "================================"
echo "Java安装状态检查"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "1. 查找Java安装目录:"
JAVA_DIRS=(
    "/data/file-redirect-learning/java-temp/portable-java"
    "/data/local/tmp/portable-java"
    "$(pwd)/java-temp/portable-java"
)

for dir in "${JAVA_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "  ✅ 找到目录: $dir"
        echo "     目录内容:"
        ls -la "$dir" | sed 's/^/        /'
        
        # 查找JDK目录
        JDK_DIRS=$(find "$dir" -maxdepth 1 -type d -name "*jdk*" 2>/dev/null)
        if [ -n "$JDK_DIRS" ]; then
            for jdk_dir in $JDK_DIRS; do
                echo "     JDK目录: $jdk_dir"
                
                # 检查bin目录
                if [ -d "$jdk_dir/bin" ]; then
                    echo "       bin目录内容:"
                    ls -la "$jdk_dir/bin" | grep java | sed 's/^/          /'
                    
                    # 检查java可执行文件
                    JAVA_BIN="$jdk_dir/bin/java"
                    if [ -f "$JAVA_BIN" ]; then
                        echo -e "       ✅ java文件存在: $JAVA_BIN"
                        if [ -x "$JAVA_BIN" ]; then
                            echo "       ✅ java文件可执行"
                            echo "       测试Java版本:"
                            "$JAVA_BIN" -version 2>&1 | sed 's/^/          /'
                        else
                            echo -e "       ❌ java文件不可执行"
                        fi
                    else
                        echo -e "       ❌ java文件不存在"
                    fi
                else
                    echo -e "       ❌ bin目录不存在"
                fi
            done
        else
            echo -e "     ❌ 未找到JDK目录"
        fi
    else
        echo -e "  ❌ 目录不存在: $dir"
    fi
done

echo
echo "2. 当前PATH中的Java:"
if command -v java >/dev/null 2>&1; then
    echo -e "  ✅ Java在PATH中可用"
    echo "     位置: $(which java)"
    echo "     版本:"
    java -version 2>&1 | sed 's/^/        /'
else
    echo -e "  ❌ Java不在PATH中"
fi

echo
echo "3. 环境变量:"
echo "  JAVA_HOME: ${JAVA_HOME:-未设置}"
echo "  PATH: $PATH"

echo
echo "4. 修复建议:"
if [ -d "/data/file-redirect-learning/java-temp/portable-java" ]; then
    cd "/data/file-redirect-learning/java-temp/portable-java"
    JDK_DIR=$(find . -maxdepth 1 -type d -name "*jdk*" | head -1)
    if [ -n "$JDK_DIR" ]; then
        FULL_JDK_PATH="/data/file-redirect-learning/java-temp/portable-java/$JDK_DIR"
        echo "  建议设置环境变量:"
        echo "    export JAVA_HOME=\"$FULL_JDK_PATH\""
        echo "    export PATH=\"\$JAVA_HOME/bin:\$PATH\""
        echo
        echo "  或者运行修复脚本:"
        echo "    ./fixed-build.sh"
    fi
fi

echo
echo "================================"
