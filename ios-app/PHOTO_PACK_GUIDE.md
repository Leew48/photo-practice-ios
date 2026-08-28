# 图片包导入说明

PhotoPractice 现在按“阅读器 App + 图片 ZIP 包”的方式工作：App 安装包保持轻量，图片不再内置到 IPA 里。你可以把图片压缩包放在 iCloud Drive、我的 iPhone、Downloads 或其它能被 iOS“文件”App 看到的位置，然后在 App 内导入。

## 推荐压缩包结构

压缩包内用文件夹作为分类，例如：

```text
PhotoLibrary.zip
└── PhotoLibrary/
    ├── 人像/
    │   ├── 001.jpg
    │   └── 002.jpg
    ├── 风景/
    │   └── 001.jpg
    └── 建筑/
        └── 001.jpg
```

也支持当前项目里的结构：

```text
PhotoLibrary/
└── ippawards-2026/
    └── photos/
        ├── Portrait/
        ├── Landscape/
        └── Architecture/
```

App 会优先把 `photos` 下面的一级文件夹识别为分类；如果没有 `photos` 文件夹，就用图片所在的上一级文件夹作为分类。

## 在 Windows 上生成图片包

在项目根目录运行：

```powershell
.\ios-app\scripts\create-photo-pack.ps1
```

生成文件：

```text
ios-app\PhotoLibrary.zip
```

## 在 iPhone 中导入

1. 把 `PhotoLibrary.zip` 放到 iCloud Drive、我的 iPhone 或下载目录。
2. 打开 PhotoPractice。
3. 进入“设置”。
4. 点“导入图片压缩包”。
5. 选择 ZIP 文件。
6. 导入完成后，首页、图库、统计都会使用新的图片包。

支持图片格式：JPG、JPEG、PNG、HEIC、HEIF、WEBP。
