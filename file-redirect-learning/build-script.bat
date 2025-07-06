@echo off
echo ================================
echo 文件重定向模块自动编译脚本
echo ================================

echo.
echo [1/4] 检查环境...
where gradlew.bat >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未找到gradlew.bat，请确保在项目根目录运行此脚本
    pause
    exit /b 1
)

echo ✅ Gradle环境正常

echo.
echo [2/4] 清理项目...
call gradlew.bat clean
if %errorlevel% neq 0 (
    echo ❌ 清理失败
    pause
    exit /b 1
)

echo ✅ 项目清理完成

echo.
echo [3/4] 编译APK...
call gradlew.bat assembleDebug
if %errorlevel% neq 0 (
    echo ❌ 编译失败
    pause
    exit /b 1
)

echo ✅ 编译成功

echo.
echo [4/4] 查找生成的APK...
for /r %%i in (*.apk) do (
    echo 找到APK: %%i
    set APK_PATH=%%i
)

if defined APK_PATH (
    echo.
    echo ================================
    echo ✅ 编译完成！
    echo APK位置: %APK_PATH%
    echo ================================
    echo.
    echo 下一步操作:
    echo 1. 将APK安装到已Root的Android设备
    echo 2. 在Xposed管理器中激活模块
    echo 3. 重启设备
    echo 4. 测试模块效果
    echo.
    echo 是否要自动安装到连接的设备？(y/n)
    set /p choice=
    if /i "%choice%"=="y" (
        echo 正在安装...
        adb install "%APK_PATH%"
        if %errorlevel% equ 0 (
            echo ✅ 安装成功！
        ) else (
            echo ❌ 安装失败，请手动安装
        )
    )
) else (
    echo ❌ 未找到生成的APK文件
)

echo.
pause
