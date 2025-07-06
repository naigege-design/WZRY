# Xposed框架基础

## 1. Xposed工作原理

### 核心机制
```
Zygote进程 → Xposed Hook → 应用进程 → 方法拦截 → 自定义逻辑
```

### Hook流程
1. **应用启动时**: Xposed在Zygote中注入代码
2. **类加载时**: 拦截目标类的加载
3. **方法调用时**: 重定向到Hook方法
4. **执行自定义逻辑**: 修改参数或返回值

## 2. Xposed模块开发基础

### 模块结构
```
XposedModule/
├── AndroidManifest.xml    # 声明Xposed模块
├── assets/
│   └── xposed_init       # 模块入口类
└── src/main/java/
    └── com/example/
        └── XposedModule.java
```

### 基础代码框架
```java
public class XposedModule implements IXposedHookLoadPackage {
    
    @Override
    public void handleLoadPackage(LoadPackageParam lpparam) throws Throwable {
        // 只Hook目标应用
        if (!lpparam.packageName.equals("com.target.app")) {
            return;
        }
        
        // Hook目标方法
        findAndHookMethod("java.io.File", lpparam.classLoader,
            "exists", new XC_MethodHook() {
                @Override
                protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                    // 方法执行前的逻辑
                }
                
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    // 方法执行后的逻辑
                }
            });
    }
}
```

## 3. 文件重定向实现

### 基本重定向Hook
```java
public class FileRedirectHook implements IXposedHookLoadPackage {
    
    private static final String TARGET_FILE_1 = "mrpcs-android-l.gr_925.data";
    private static final String TARGET_FILE_2 = "mrpcs-android-1.gr_925.data";
    
    @Override
    public void handleLoadPackage(LoadPackageParam lpparam) throws Throwable {
        if (!lpparam.packageName.equals("com.tencent.tmgp.sgame")) {
            return;
        }
        
        // Hook File.exists()
        hookFileExists(lpparam.classLoader);
        
        // Hook FileInputStream
        hookFileInputStream(lpparam.classLoader);
        
        // Hook Native方法
        hookNativeMethods(lpparam.classLoader);
    }
    
    private void hookFileExists(ClassLoader classLoader) {
        findAndHookMethod("java.io.File", classLoader, "exists", 
            new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.thisObject;
                    String fileName = file.getName();
                    
                    // 如果是目标文件，返回false
                    if (TARGET_FILE_1.equals(fileName) || TARGET_FILE_2.equals(fileName)) {
                        param.setResult(false);
                        XposedBridge.log("Blocked file access: " + fileName);
                    }
                }
            });
    }
    
    private void hookFileInputStream(ClassLoader classLoader) {
        findAndHookConstructor("java.io.FileInputStream", classLoader, 
            File.class, new XC_MethodHook() {
                @Override
                protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.args[0];
                    String fileName = file.getName();
                    
                    // 重定向到空文件
                    if (TARGET_FILE_1.equals(fileName) || TARGET_FILE_2.equals(fileName)) {
                        File emptyFile = new File("/dev/null");
                        param.args[0] = emptyFile;
                        XposedBridge.log("Redirected file: " + fileName + " -> /dev/null");
                    }
                }
            });
    }
}
```

## 4. 高级重定向技术

### 动态文件替换
```java
private void createFakeFile(String originalPath) {
    try {
        File fakeFile = new File("/data/local/tmp/fake_" + System.currentTimeMillis());
        FileOutputStream fos = new FileOutputStream(fakeFile);
        // 写入伪造的数据
        fos.write(new byte[0]); // 空文件
        fos.close();
        
        // 使用符号链接替换原文件
        Runtime.getRuntime().exec("ln -sf " + fakeFile.getAbsolutePath() + " " + originalPath);
    } catch (Exception e) {
        XposedBridge.log("Failed to create fake file: " + e.getMessage());
    }
}
```

### 内存中文件映射
```java
private Map<String, byte[]> virtualFiles = new HashMap<>();

private void setupVirtualFile(String path, byte[] content) {
    virtualFiles.put(path, content);
}

// 在FileInputStream Hook中使用虚拟文件
if (virtualFiles.containsKey(file.getAbsolutePath())) {
    byte[] virtualContent = virtualFiles.get(file.getAbsolutePath());
    ByteArrayInputStream bis = new ByteArrayInputStream(virtualContent);
    // 替换原始的FileInputStream
}
```

## 5. 调试和测试

### 日志输出
```java
XposedBridge.log("Hook executed: " + methodName);
```

### 异常处理
```java
try {
    // Hook逻辑
} catch (Throwable t) {
    XposedBridge.log("Hook failed: " + t.getMessage());
}
```

## 下一步
学习Native层Hook技术 → [03-native-hook-techniques.md](03-native-hook-techniques.md)
