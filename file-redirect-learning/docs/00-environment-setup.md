# 环境准备和工具安装指南

## 1. 必需工具清单

### 开发环境
- [ ] **Android Studio** - 最新版本
- [ ] **Java JDK 8+** - Android开发必需
- [ ] **Android SDK** - API Level 21+
- [ ] **Git** - 版本控制

### 设备要求
- [ ] **Android设备** (物理设备，推荐Android 7.0+)
- [ ] **Root权限** - 必须获取Root权限
- [ ] **Xposed框架** - LSPosed或EdXposed

### 调试工具
- [ ] **ADB** - Android调试桥
- [ ] **文件管理器** - 支持Root权限的文件管理器
- [ ] **日志查看器** - 如Logcat或专门的日志应用

## 2. 详细安装步骤

### 2.1 安装Android Studio
1. 下载Android Studio: https://developer.android.com/studio
2. 安装并配置SDK
3. 创建虚拟设备（可选，推荐使用真机）

### 2.2 设备Root准备
```bash
# 检查设备是否已Root
adb shell su -c "id"

# 如果返回uid=0(root)，说明已获取Root权限
```

**Root方法（因设备而异）：**
- **Magisk** - 推荐的现代Root方案
- **SuperSU** - 传统Root方案
- **KingRoot** - 一键Root工具（部分设备）

### 2.3 安装Xposed框架

#### 方案A: LSPosed (推荐)
```bash
# 1. 下载LSPosed模块
# 从GitHub下载: https://github.com/LSPosed/LSPosed

# 2. 通过Magisk安装
# 将zip文件放入Magisk模块中安装

# 3. 重启设备
adb reboot
```

#### 方案B: EdXposed
```bash
# 1. 安装EdXposed框架
# 下载地址: https://github.com/ElderDrivers/EdXposed

# 2. 通过Magisk或Recovery安装
# 3. 安装EdXposed Manager应用
```

### 2.4 验证环境
```bash
# 检查Xposed是否正常工作
adb shell am start -n org.lsposed.manager/.ui.activity.MainActivity

# 查看Xposed日志
adb logcat | grep -i xposed
```

## 3. 开发环境配置

### 3.1 Android Studio项目设置
```gradle
// 在app/build.gradle中添加
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
    }
}

dependencies {
    // Xposed API
    compileOnly 'de.robv.android.xposed:api:82'
    compileOnly 'de.robv.android.xposed:api:82:sources'
}
```

### 3.2 项目结构创建
```bash
# 创建项目目录结构
mkdir -p file-redirect-learning/xposed-module/src/main/java/com/example/fileredirect
mkdir -p file-redirect-learning/xposed-module/src/main/assets
mkdir -p file-redirect-learning/test-app/src/main/java/com/example/testapp
```

## 4. 测试环境验证

### 4.1 创建简单测试
```java
// 创建测试应用验证环境
public class TestActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 测试文件访问
        File testFile = new File(getFilesDir(), "test.txt");
        Log.d("TEST", "File exists: " + testFile.exists());
    }
}
```

### 4.2 验证Xposed工作
```bash
# 查看Xposed模块列表
adb shell am start -n org.lsposed.manager/.ui.activity.MainActivity

# 检查模块是否被识别
adb logcat | grep -i "xposed\|lsposed"
```

## 5. 常见问题解决

### 问题1: 设备无法Root
**解决方案:**
- 查找设备专用的Root方法
- 考虑使用模拟器（如Genymotion）
- 使用已Root的测试设备

### 问题2: Xposed框架安装失败
**解决方案:**
```bash
# 检查Magisk版本兼容性
adb shell magisk --version

# 尝试不同版本的LSPosed
# 查看安装日志
adb logcat | grep -i magisk
```

### 问题3: 模块无法加载
**解决方案:**
- 检查AndroidManifest.xml配置
- 验证xposed_init文件内容
- 查看Xposed日志排错

## 6. 下一步行动

完成环境准备后：
1. ✅ 验证所有工具正常工作
2. ➡️ 开始理论学习阶段
3. ➡️ 编译和测试第一个Xposed模块

## 7. 快速检查清单

```bash
# 运行这个脚本检查环境
#!/bin/bash
echo "=== 环境检查 ==="

# 检查ADB
adb version && echo "✅ ADB OK" || echo "❌ ADB 未安装"

# 检查设备连接
adb devices | grep -q device && echo "✅ 设备已连接" || echo "❌ 设备未连接"

# 检查Root权限
adb shell su -c "echo '✅ Root权限正常'" 2>/dev/null || echo "❌ 无Root权限"

# 检查Xposed
adb shell pm list packages | grep -q lsposed && echo "✅ LSPosed已安装" || echo "❌ Xposed未安装"

echo "=== 检查完成 ==="
```

准备好环境后，请告诉我您的进展！
