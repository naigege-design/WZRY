package com.example.fileredirect;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;
import java.io.File;

/**
 * 文件重定向模块主界面
 * 用于显示模块状态和测试功能
 */
public class MainActivity extends Activity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 创建简单的UI
        TextView textView = new TextView(this);
        textView.setText(getModuleInfo());
        textView.setPadding(50, 50, 50, 50);
        setContentView(textView);
        
        // 显示模块状态
        Toast.makeText(this, "文件重定向模块已安装", Toast.LENGTH_LONG).show();
        
        // 测试文件访问
        testFileAccess();
    }
    
    private String getModuleInfo() {
        StringBuilder info = new StringBuilder();
        info.append("文件重定向学习模块\n\n");
        info.append("版本: 1.0\n");
        info.append("作者: 学习项目\n\n");
        info.append("功能说明:\n");
        info.append("• 拦截目标文件的访问\n");
        info.append("• 重定向文件读取请求\n");
        info.append("• 学习Hook技术原理\n\n");
        info.append("目标文件:\n");
        info.append("• mrpcs-android-l.gr_925.data\n");
        info.append("• mrpcs-android-1.gr_925.data\n\n");
        info.append("使用说明:\n");
        info.append("1. 在Xposed管理器中激活此模块\n");
        info.append("2. 重启设备\n");
        info.append("3. 运行目标应用进行测试\n\n");
        info.append("⚠️ 仅用于学习目的，请勿用于非法用途");
        
        return info.toString();
    }
    
    private void testFileAccess() {
        // 创建测试文件
        File testFile1 = new File(getFilesDir(), "mrpcs-android-l.gr_925.data");
        File testFile2 = new File(getFilesDir(), "mrpcs-android-1.gr_925.data");
        
        try {
            // 尝试创建文件
            testFile1.createNewFile();
            testFile2.createNewFile();
            
            // 测试文件访问（如果模块工作正常，这些应该被拦截）
            boolean exists1 = testFile1.exists();
            boolean exists2 = testFile2.exists();
            
            String result = "测试结果:\n";
            result += "文件1存在: " + exists1 + "\n";
            result += "文件2存在: " + exists2 + "\n";
            
            if (!exists1 && !exists2) {
                result += "\n✅ Hook可能正在工作";
            } else {
                result += "\n❌ Hook可能未生效";
            }
            
            Toast.makeText(this, result, Toast.LENGTH_LONG).show();
            
        } catch (Exception e) {
            Toast.makeText(this, "测试失败: " + e.getMessage(), Toast.LENGTH_LONG).show();
        }
    }
}
