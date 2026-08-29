# PhotoPractice Android 构建与安装

这个目录是安卓版本的看图计划。安卓测试不需要 Apple Developer Program，也不需要 iPhone 开发者模式。

## 用 Codemagic 构建 APK

1. 打开 Codemagic 项目 `photo-practice-ios`。
2. 点击 `Start new build`。
3. Workflow 选择 `PhotoPractice Android Debug APK`。
4. Branch 选择 `main`。
5. 开始构建。
6. 构建完成后，在 `Artifacts` 下载：
   `app-debug.apk`

## 安装到安卓手机

1. 把 `app-debug.apk` 发送到安卓手机。
2. 在手机文件管理器里点击 APK。
3. 如果系统提示，允许“安装未知来源应用”。
4. 安装完成后打开 `看图计划`。

## 导入图片包

1. 把 `PhotoLibrary.zip` 放到安卓手机的任意位置，比如 `Download` 文件夹。
2. 打开 App 的 `设置`。
3. 点击 `导入图片 ZIP`。
4. 选择 `PhotoLibrary.zip`。
5. 等待导入完成。导入后图片保存在 App 私有目录，可离线使用。

## 当前 Android 版已包含

- 今日页统计
- 看图页
- 图片 ZIP 导入
- 6078 张照片元数据匹配
- 已看 / 收藏记录
- 回顾记录
- 长按照片全屏查看
- 全屏双指缩放和拖动查看细节
- 马卡龙配色基础 UI
