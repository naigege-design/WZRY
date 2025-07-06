package com.example.fileredirect;

import java.io.File;
import java.io.FileInputStream;
import java.io.ByteArrayInputStream;
import java.util.HashMap;
import java.util.Map;

import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.XposedHelpers;
import de.robv.android.xposed.callbacks.XC_LoadPackage.LoadPackageParam;

/**
 * 文件重定向Xposed模块
 * 用于学习文件访问拦截和重定向技术
 */
public class FileRedirectModule implements IXposedHookLoadPackage {
    
    // 目标文件名
    private static final String TARGET_FILE_1 = "mrpcs-android-l.gr_925.data";
    private static final String TARGET_FILE_2 = "mrpcs-android-1.gr_925.data";
    
    // 虚拟文件存储
    private static final Map<String, byte[]> virtualFiles = new HashMap<>();
    
    static {
        // 初始化虚拟文件（空内容）
        virtualFiles.put(TARGET_FILE_1, new byte[0]);
        virtualFiles.put(TARGET_FILE_2, new byte[0]);
    }
    
    @Override
    public void handleLoadPackage(LoadPackageParam lpparam) throws Throwable {
        // 只Hook目标应用（这里使用通用包名，实际使用时需要指定具体应用）
        if (lpparam.packageName.equals("com.tencent.tmgp.sgame") || 
            lpparam.packageName.equals("com.example.testapp")) {
            
            XposedBridge.log("FileRedirect: Hooking package " + lpparam.packageName);
            
            // Hook文件存在性检查
            hookFileExists(lpparam.classLoader);
            
            // Hook文件输入流
            hookFileInputStream(lpparam.classLoader);
            
            // Hook文件长度获取
            hookFileLength(lpparam.classLoader);
            
            // Hook文件删除
            hookFileDelete(lpparam.classLoader);
        }
    }
    
    /**
     * Hook File.exists() 方法
     */
    private void hookFileExists(ClassLoader classLoader) {
        XposedHelpers.findAndHookMethod("java.io.File", classLoader, "exists", 
            new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.thisObject;
                    String fileName = file.getName();
                    String filePath = file.getAbsolutePath();
                    
                    // 检查是否为目标文件
                    if (isTargetFile(fileName)) {
                        // 返回false，让应用认为文件不存在
                        param.setResult(false);
                        XposedBridge.log("FileRedirect: Blocked exists() for " + fileName);
                    }
                }
            });
    }
    
    /**
     * Hook FileInputStream 构造函数
     */
    private void hookFileInputStream(ClassLoader classLoader) {
        // Hook File参数的构造函数
        XposedHelpers.findAndHookConstructor("java.io.FileInputStream", classLoader, 
            File.class, new XC_MethodHook() {
                @Override
                protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.args[0];
                    String fileName = file.getName();
                    
                    if (isTargetFile(fileName)) {
                        // 创建临时空文件
                        File tempFile = createTempEmptyFile();
                        param.args[0] = tempFile;
                        XposedBridge.log("FileRedirect: Redirected FileInputStream for " + fileName);
                    }
                }
            });
        
        // Hook String路径参数的构造函数
        XposedHelpers.findAndHookConstructor("java.io.FileInputStream", classLoader, 
            String.class, new XC_MethodHook() {
                @Override
                protected void beforeHookedMethod(MethodHookParam param) throws Throwable {
                    String filePath = (String) param.args[0];
                    String fileName = new File(filePath).getName();
                    
                    if (isTargetFile(fileName)) {
                        // 重定向到/dev/null或临时空文件
                        param.args[0] = "/dev/null";
                        XposedBridge.log("FileRedirect: Redirected FileInputStream path for " + fileName);
                    }
                }
            });
    }
    
    /**
     * Hook File.length() 方法
     */
    private void hookFileLength(ClassLoader classLoader) {
        XposedHelpers.findAndHookMethod("java.io.File", classLoader, "length", 
            new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.thisObject;
                    String fileName = file.getName();
                    
                    if (isTargetFile(fileName)) {
                        // 返回0长度
                        param.setResult(0L);
                        XposedBridge.log("FileRedirect: Returned 0 length for " + fileName);
                    }
                }
            });
    }
    
    /**
     * Hook File.delete() 方法
     */
    private void hookFileDelete(ClassLoader classLoader) {
        XposedHelpers.findAndHookMethod("java.io.File", classLoader, "delete", 
            new XC_MethodHook() {
                @Override
                protected void afterHookedMethod(MethodHookParam param) throws Throwable {
                    File file = (File) param.thisObject;
                    String fileName = file.getName();
                    
                    if (isTargetFile(fileName)) {
                        // 返回true，让应用认为删除成功
                        param.setResult(true);
                        XposedBridge.log("FileRedirect: Faked delete success for " + fileName);
                    }
                }
            });
    }
    
    /**
     * 检查是否为目标文件
     */
    private boolean isTargetFile(String fileName) {
        return TARGET_FILE_1.equals(fileName) || TARGET_FILE_2.equals(fileName) ||
               fileName.contains("gr_925.data");
    }
    
    /**
     * 创建临时空文件
     */
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
