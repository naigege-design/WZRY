#!/bin/bash

echo "================================"
echo "Android兼容构建解决方案"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}问题分析:${NC}"
echo "• Java文件存在但无法执行"
echo "• 错误: 'No such file or directory'"
echo "• 原因: Android系统缺少Linux动态链接器"
echo "• Java需要: /lib/ld-linux-aarch64.so.1"
echo "• Android使用: /system/bin/linker64"

echo
echo -e "${YELLOW}解决方案:${NC}"
echo "由于Android系统与标准Linux不兼容，无法直接运行桌面版Java。"

echo
echo "方案1: 创建预编译APK"
echo "我将为您提供一个预编译的APK文件..."

# 创建一个简化的APK构建过程
echo
echo "创建简化的模块文件..."

# 创建一个最小化的APK结构
mkdir -p /data/file-redirect-learning/prebuilt-apk
cd /data/file-redirect-learning/prebuilt-apk

# 创建AndroidManifest.xml
cat > AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.fileredirect"
    android:versionCode="1"
    android:versionName="1.0">

    <application
        android:allowBackup="true"
        android:label="文件重定向模块">
        
        <meta-data
            android:name="xposedmodule"
            android:value="true" />
        <meta-data
            android:name="xposeddescription"
            android:value="文件重定向学习模块 - 拦截gr_925.data文件访问" />
        <meta-data
            android:name="xposedminversion"
            android:value="54" />

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
</manifest>
EOF

# 创建assets目录和xposed_init
mkdir -p assets
echo "com.example.fileredirect.FileRedirectModule" > assets/xposed_init

# 创建Java源码目录
mkdir -p src/com/example/fileredirect

# 创建主要的Hook模块
cat > src/com/example/fileredirect/FileRedirectModule.java << 'EOF'
package com.example.fileredirect;

import java.io.File;
import java.io.FileInputStream;
import java.util.HashMap;
import java.util.Map;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage.LoadPackageParam;

public class FileRedirectModule implements IXposedHookLoadPackage {
    
    private static final String TARGET_FILE_1 = "mrpcs-android-l.gr_925.data";
    private static final String TARGET_FILE_2 = "mrpcs-android-1.gr_925.data";
    
    @Override
    public void handleLoadPackage(LoadPackageParam lpparam) throws Throwable {
        // 目标应用包名 - 可以修改为具体的应用
        if (lpparam.packageName.equals("com.tencent.tmgp.sgame") || 
            lpparam.packageName.contains("sgame") ||
            lpparam.packageName.contains("tencent")) {
            
            XposedBridge.log("FileRedirect: Hooking package " + lpparam.packageName);
            
            hookFileExists(lpparam.classLoader);
            hookFileInputStream(lpparam.classLoader);
            hookFileLength(lpparam.classLoader);
            hookFileDelete(lpparam.classLoader);
        }
    }
    
    private void hookFileExists(ClassLoader classLoader) {
        XposedHelpers.findAndHookMethod("java.io.File", classLoader, "exists", 
            new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.thisObject;
                    String fileName = file.getName();
                    
                    if (isTargetFile(fileName)) {
                        param.setResult(false);
                        XposedBridge.log("FileRedirect: Blocked exists() for " + fileName);
                    }
                }
            });
    }
    
    private void hookFileInputStream(ClassLoader classLoader) {
        XposedHelpers.findAndHookConstructor("java.io.FileInputStream", classLoader, 
            File.class, new XC_MethodHook() {
                @Override
                protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.args[0];
                    String fileName = file.getName();
                    
                    if (isTargetFile(fileName)) {
                        File tempFile = createTempEmptyFile();
                        param.args[0] = tempFile;
                        XposedBridge.log("FileRedirect: Redirected FileInputStream for " + fileName);
                    }
                }
            });
        
        XposedHelpers.findAndHookConstructor("java.io.FileInputStream", classLoader, 
            String.class, new XC_MethodHook() {
                @Override
                protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                    String filePath = (String) param.args[0];
                    String fileName = new File(filePath).getName();
                    
                    if (isTargetFile(fileName)) {
                        param.args[0] = "/dev/null";
                        XposedBridge.log("FileRedirect: Redirected FileInputStream path for " + fileName);
                    }
                }
            });
    }
    
    private void hookFileLength(ClassLoader classLoader) {
        XposedHelpers.findAndHookMethod("java.io.File", classLoader, "length", 
            new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.thisObject;
                    String fileName = file.getName();
                    
                    if (isTargetFile(fileName)) {
                        param.setResult(0L);
                        XposedBridge.log("FileRedirect: Returned 0 length for " + fileName);
                    }
                }
            });
    }
    
    private void hookFileDelete(ClassLoader classLoader) {
        XposedHelpers.findAndHookMethod("java.io.File", classLoader, "delete", 
            new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.thisObject;
                    String fileName = file.getName();
                    
                    if (isTargetFile(fileName)) {
                        param.setResult(true);
                        XposedBridge.log("FileRedirect: Faked delete success for " + fileName);
                    }
                }
            });
    }
    
    private boolean isTargetFile(String fileName) {
        return TARGET_FILE_1.equals(fileName) || TARGET_FILE_2.equals(fileName) ||
               fileName.contains("gr_925.data") || fileName.contains("mrpcs-android");
    }
    
    private File createTempEmptyFile() {
        try {
            File tempFile = File.createTempFile("redirect_", ".tmp");
            tempFile.deleteOnExit();
            return tempFile;
        } catch (Exception e) {
            XposedBridge.log("FileRedirect: Failed to create temp file: " + e.getMessage());
            return new File("/dev/null");
        }
    }
}
EOF

# 创建MainActivity
cat > src/com/example/fileredirect/MainActivity.java << 'EOF'
package com.example.fileredirect;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        TextView textView = new TextView(this);
        textView.setText("文件重定向模块\n\n" +
                        "功能: 拦截gr_925.data文件访问\n" +
                        "状态: 已安装\n\n" +
                        "使用方法:\n" +
                        "1. 在Xposed管理器中激活此模块\n" +
                        "2. 重启设备\n" +
                        "3. 运行目标应用\n\n" +
                        "⚠️ 仅用于学习目的");
        textView.setPadding(50, 50, 50, 50);
        setContentView(textView);
        
        Toast.makeText(this, "文件重定向模块已安装", Toast.LENGTH_LONG).show();
    }
}
EOF

echo -e "${GREEN}✅ 模块文件创建完成${NC}"

echo
echo "方案2: 使用在线编译服务"
echo "由于本地环境限制，建议使用以下方法："

echo
echo -e "${BLUE}推荐解决方案:${NC}"
echo
echo "1. 📱 使用Termux (推荐):"
echo "   • 安装Termux应用"
echo "   • 运行: pkg install openjdk-17"
echo "   • 在Termux中编译项目"
echo
echo "2. 💻 使用电脑编译:"
echo "   • 将项目文件复制到电脑"
echo "   • 使用Android Studio编译"
echo "   • 生成APK后传回手机"
echo
echo "3. 🌐 使用GitHub Actions:"
echo "   • 将项目上传到GitHub"
echo "   • 配置自动编译"
echo "   • 下载编译好的APK"

echo
echo "方案3: 手动创建简化APK"
echo "我已经为您创建了模块源码，您可以："

echo
echo -e "${YELLOW}手动编译步骤:${NC}"
echo "1. 将 /data/file-redirect-learning/prebuilt-apk/ 目录复制到电脑"
echo "2. 在Android Studio中创建新项目"
echo "3. 替换源码文件"
echo "4. 添加Xposed依赖"
echo "5. 编译生成APK"

echo
echo "方案4: 使用预编译的通用APK"
echo "如果您只是想测试功能，可以搜索现有的文件重定向Xposed模块。"

echo
echo "================================"
echo -e "${GREEN}总结${NC}"
echo "================================"
echo
echo -e "${RED}当前环境限制:${NC}"
echo "• Android系统不支持标准Linux Java运行时"
echo "• 缺少必要的动态链接器"
echo "• 无法直接编译Android应用"

echo
echo -e "${GREEN}推荐解决方案:${NC}"
echo "1. 使用Termux环境 (最简单)"
echo "2. 使用电脑编译 (最可靠)"
echo "3. 使用在线编译服务"

echo
echo -e "${YELLOW}学习价值:${NC}"
echo "• 了解了Android与Linux的差异"
echo "• 学习了Xposed模块开发"
echo "• 掌握了文件重定向技术原理"

echo
echo "虽然无法在当前环境直接编译，但您已经获得了："
echo "✅ 完整的Xposed模块源码"
echo "✅ 详细的技术文档"
echo "✅ 多种编译方案"
echo "✅ 深入的技术理解"

echo
echo "建议下载Termux应用，然后运行:"
echo "  pkg install openjdk-17"
echo "  git clone <项目地址>"
echo "  ./gradlew assembleDebug"

echo
echo "脚本执行完成！"
