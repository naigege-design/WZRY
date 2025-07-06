# Android文件系统基础

## 1. Android文件系统结构

### 主要目录
```
/system/          # 系统文件
/data/            # 应用数据
/sdcard/          # 外部存储
/proc/            # 进程信息
/dev/             # 设备文件
```

### 应用数据目录
```
/data/data/[package_name]/
├── files/        # 私有文件
├── cache/        # 缓存文件
├── databases/    # 数据库文件
└── shared_prefs/ # SharedPreferences
```

## 2. 文件权限模型

### Linux权限基础
```bash
# 权限表示：rwxrwxrwx
# r(4) = 读权限
# w(2) = 写权限  
# x(1) = 执行权限

# 示例：644 = rw-r--r--
chmod 644 filename
```

### Android特殊权限
- SELinux上下文
- 应用沙盒隔离
- 用户ID隔离

## 3. 文件访问系统调用

### 主要系统调用
```c
// 打开文件
int open(const char *pathname, int flags);

// 读取文件
ssize_t read(int fd, void *buf, size_t count);

// 写入文件
ssize_t write(int fd, const void *buf, size_t count);

// 关闭文件
int close(int fd);

// 获取文件信息
int stat(const char *pathname, struct stat *statbuf);
```

## 4. 文件访问流程

```
应用调用 → Java API → JNI → Native代码 → 系统调用 → 内核 → 文件系统
```

### Hook点分析
1. **Java层Hook**: 拦截File类方法
2. **JNI层Hook**: 拦截native方法调用
3. **系统调用Hook**: 拦截open/read/write等

## 5. 实际案例分析

### 游戏文件访问模式
```java
// 典型的文件检查流程
File dataFile = new File("/data/data/com.game/files/config.data");
if (dataFile.exists()) {
    // 读取配置
    FileInputStream fis = new FileInputStream(dataFile);
    // ... 处理数据
}
```

### Hook拦截点
```java
// 可以在以下位置进行拦截：
1. File.exists() 方法
2. FileInputStream构造函数
3. Native层的open()系统调用
```

## 下一步
学习Xposed框架基础 → [02-xposed-framework-basics.md](02-xposed-framework-basics.md)
