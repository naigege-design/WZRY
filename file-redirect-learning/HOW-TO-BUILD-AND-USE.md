# 如何打包和使用文件重定向模块

## 📦 项目打包步骤

### 方法一：手机终端编译（推荐用于学习）

**适用于：** Termux、Linux Deploy等Android终端环境

1. **环境检查**
   ```bash
   # 首先运行环境检查
   chmod +x check-environment.sh
   ./check-environment.sh
   ```

2. **安装Java（如果未安装）**
   ```bash
   # 在Termux中
   pkg update
   pkg install openjdk-17
   ```

3. **一键编译**
   ```bash
   # 使用手机专用构建脚本
   chmod +x build-mobile.sh
   ./build-mobile.sh
   ```

### 方法二：使用Android Studio（电脑端）

1. **打开项目**
   ```bash
   # 用Android Studio打开file-redirect-learning目录
   File -> Open -> 选择file-redirect-learning文件夹
   ```

2. **同步项目**
   - 等待Gradle同步完成
   - 如果有错误，检查SDK版本和依赖

3. **编译APK**
   ```
   Build -> Build Bundle(s) / APK(s) -> Build APK(s)
   ```

### 方法三：命令行编译

1. **进入项目目录**
   ```bash
   cd file-redirect-learning
   ```

2. **设置权限**
   ```bash
   chmod +x gradlew
   chmod +x *.sh
   ```

3. **编译项目**
   ```bash
   # Windows
   gradlew.bat assembleDebug

   # Linux/Mac/Android
   ./gradlew assembleDebug
   ```

4. **查找生成的APK**
   ```bash
   find . -name "*.apk"
   ```

## 📱 安装和使用步骤

### 第一步：准备设备
```bash
# 1. 确保设备已Root
adb shell su -c "id"

# 2. 确保安装了Xposed框架（LSPosed或EdXposed）
adb shell pm list packages | grep lsposed
```

### 第二步：安装模块
```bash
# 1. 安装APK到设备
adb install xposed-module-debug.apk

# 2. 或者手动安装
# 将APK文件传输到设备，然后在设备上安装
```

### 第三步：激活模块
1. 打开**LSPosed管理器**或**EdXposed管理器**
2. 在**模块**列表中找到"文件重定向模块"
3. **勾选激活**该模块
4. 选择**作用域**（目标应用）
   - 可以选择特定应用（如王者荣耀）
   - 或选择系统范围

### 第四步：重启设备
```bash
adb reboot
```

## 🧪 测试模块效果

### 创建测试应用
```bash
# 1. 创建测试文件
adb shell "echo 'test' > /data/local/tmp/mrpcs-android-l.gr_925.data"

# 2. 运行测试
adb shell "ls -la /data/local/tmp/mrpcs-android-*.data"
```

### 查看日志
```bash
# 查看Xposed日志
adb logcat | grep -i "FileRedirect\|Xposed"

# 查看模块日志
adb logcat | grep "com.example.fileredirect"
```

### 测试应用
1. 打开安装的"文件重定向模块"应用
2. 查看模块状态和测试结果
3. 检查是否显示"Hook可能正在工作"

## 🔧 自定义配置

### 修改目标文件
编辑 `FileRedirectModule.java`：
```java
// 修改这些常量来改变目标文件
private static final String TARGET_FILE_1 = "your-target-file-1.data";
private static final String TARGET_FILE_2 = "your-target-file-2.data";
```

### 修改目标应用
编辑 `FileRedirectModule.java`：
```java
// 修改目标应用包名
if (lpparam.packageName.equals("com.your.target.app")) {
    // Hook逻辑
}
```

### 重新编译
```bash
# 修改后重新编译
./gradlew assembleDebug

# 卸载旧版本
adb uninstall com.example.fileredirect

# 安装新版本
adb install xposed-module/build/outputs/apk/debug/xposed-module-debug.apk
```

## 🐛 常见问题解决

### 问题1：编译失败
```bash
# 检查Java版本
java -version

# 清理项目
./gradlew clean

# 重新编译
./gradlew assembleDebug
```

### 问题2：模块不生效
```bash
# 检查Xposed框架状态
adb shell am start -n org.lsposed.manager/.ui.activity.MainActivity

# 查看模块是否被识别
adb logcat | grep -i xposed

# 确认模块已激活并重启
```

### 问题3：权限问题
```bash
# 检查Root权限
adb shell su -c "whoami"

# 检查SELinux状态
adb shell getenforce

# 如果是Enforcing，可能需要设置为Permissive（仅测试用）
adb shell su -c "setenforce 0"
```

## 📋 完整使用流程总结

1. ✅ **环境准备**：Root设备 + Xposed框架
2. ✅ **编译项目**：使用Android Studio或命令行
3. ✅ **安装模块**：安装生成的APK
4. ✅ **激活模块**：在Xposed管理器中激活
5. ✅ **重启设备**：让模块生效
6. ✅ **测试验证**：检查Hook效果
7. ✅ **查看日志**：确认模块正常工作

## ⚠️ 重要提醒

- **仅用于学习目的**，请勿用于破解商业软件
- **备份重要数据**，Root和Xposed可能有风险
- **遵守法律法规**，不要用于非法用途
- **测试环境**，建议在测试设备上使用

完成这些步骤后，您就可以开始学习和研究文件重定向技术了！
