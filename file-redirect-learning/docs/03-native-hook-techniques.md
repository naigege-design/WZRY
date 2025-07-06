# Native层Hook技术

## 1. Native Hook原理

### 系统调用拦截
```c
// 原始系统调用流程
应用 → libc → 系统调用 → 内核

// Hook后的流程  
应用 → libc → Hook函数 → 自定义逻辑 → 原始函数 → 内核
```

### Hook实现方式
1. **PLT Hook**: 修改程序链接表
2. **Inline Hook**: 直接修改函数指令
3. **GOT Hook**: 修改全局偏移表

## 2. 使用Frida进行Native Hook

### Frida基础
```javascript
// 连接到目标进程
Java.perform(function() {
    // Hook Java层
    var File = Java.use("java.io.File");
    File.exists.implementation = function() {
        var fileName = this.getName();
        if (fileName.indexOf("gr_925.data") !== -1) {
            console.log("[+] Blocked file access: " + fileName);
            return false;
        }
        return this.exists();
    };
});
```

### Native函数Hook
```javascript
// Hook native函数
var openPtr = Module.findExportByName("libc.so", "open");
if (openPtr) {
    Interceptor.attach(openPtr, {
        onEnter: function(args) {
            var path = Memory.readUtf8String(args[0]);
            if (path.indexOf("gr_925.data") !== -1) {
                console.log("[+] Intercepted open(): " + path);
                // 重定向到/dev/null
                args[0] = Memory.allocUtf8String("/dev/null");
            }
        },
        onLeave: function(retval) {
            // 处理返回值
        }
    });
}
```

## 3. 自定义Native Hook库

### 基础Hook框架
```c
#include <dlfcn.h>
#include <fcntl.h>
#include <string.h>
#include <android/log.h>

#define LOG_TAG "FileRedirectHook"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

// 原始函数指针
static int (*original_open)(const char *pathname, int flags, ...) = NULL;

// Hook函数
int open(const char *pathname, int flags, ...) {
    // 检查是否为目标文件
    if (strstr(pathname, "gr_925.data") != NULL) {
        LOGD("Redirecting file access: %s", pathname);
        // 重定向到/dev/null
        return original_open("/dev/null", flags);
    }
    
    // 调用原始函数
    return original_open(pathname, flags);
}

// 初始化Hook
__attribute__((constructor))
void init_hook() {
    // 获取原始函数地址
    original_open = dlsym(RTLD_NEXT, "open");
    if (original_open == NULL) {
        LOGD("Failed to get original open function");
    } else {
        LOGD("Hook initialized successfully");
    }
}
```

### 编译配置
```makefile
# Android.mk
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := fileredirect
LOCAL_SRC_FILES := hook.c
LOCAL_LDLIBS := -llog -ldl
include $(BUILD_SHARED_LIBRARY)
```

## 4. 高级重定向技术

### 虚拟文件系统
```c
#include <sys/stat.h>
#include <errno.h>

// 虚拟文件映射
typedef struct {
    char path[256];
    char* content;
    size_t size;
} virtual_file_t;

static virtual_file_t virtual_files[] = {
    {"/data/data/com.game/files/mrpcs-android-l.gr_925.data", "", 0},
    {"/data/data/com.game/files/mrpcs-android-1.gr_925.data", "", 0}
};

// Hook stat函数
int stat(const char *pathname, struct stat *statbuf) {
    for (int i = 0; i < sizeof(virtual_files)/sizeof(virtual_file_t); i++) {
        if (strcmp(pathname, virtual_files[i].path) == 0) {
            // 返回虚拟文件信息
            memset(statbuf, 0, sizeof(struct stat));
            statbuf->st_mode = S_IFREG | 0644;
            statbuf->st_size = virtual_files[i].size;
            return 0;
        }
    }
    
    // 调用原始函数
    return original_stat(pathname, statbuf);
}
```

### 内存映射重定向
```c
#include <sys/mman.h>

void* mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset) {
    // 检查文件描述符对应的文件
    char fd_path[256];
    snprintf(fd_path, sizeof(fd_path), "/proc/self/fd/%d", fd);
    
    char real_path[256];
    ssize_t len = readlink(fd_path, real_path, sizeof(real_path) - 1);
    if (len > 0) {
        real_path[len] = '\0';
        if (strstr(real_path, "gr_925.data") != NULL) {
            // 映射到空内存区域
            return mmap(addr, length, prot, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        }
    }
    
    return original_mmap(addr, length, prot, flags, fd, offset);
}
```

## 5. 动态加载和注入

### 使用LD_PRELOAD
```bash
# 设置环境变量
export LD_PRELOAD="/data/local/tmp/libfileredirect.so"

# 启动目标应用
am start -n com.target.app/.MainActivity
```

### 运行时注入
```c
#include <sys/ptrace.h>

// 注入共享库到目标进程
int inject_library(pid_t pid, const char* lib_path) {
    // 1. 附加到目标进程
    if (ptrace(PTRACE_ATTACH, pid, NULL, NULL) == -1) {
        return -1;
    }
    
    // 2. 获取dlopen地址
    void* dlopen_addr = get_remote_addr(pid, "dlopen");
    
    // 3. 在目标进程中调用dlopen
    call_remote_function(pid, dlopen_addr, lib_path, RTLD_NOW);
    
    // 4. 分离进程
    ptrace(PTRACE_DETACH, pid, NULL, NULL);
    
    return 0;
}
```

## 6. 测试和验证

### 测试脚本
```bash
#!/bin/bash

# 编译Hook库
ndk-build

# 推送到设备
adb push libs/arm64-v8a/libfileredirect.so /data/local/tmp/

# 设置权限
adb shell chmod 755 /data/local/tmp/libfileredirect.so

# 测试Hook效果
adb shell "LD_PRELOAD=/data/local/tmp/libfileredirect.so /data/local/tmp/test_app"
```

### 验证方法
```c
// 测试程序
int main() {
    // 测试文件访问
    FILE* fp = fopen("/data/test/gr_925.data", "r");
    if (fp == NULL) {
        printf("File access blocked successfully\n");
    } else {
        printf("Hook failed\n");
        fclose(fp);
    }
    return 0;
}
```

## 下一步
学习实际部署和测试 → [04-deployment-and-testing.md](04-deployment-and-testing.md)
