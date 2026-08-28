# Windows + Sideloadly 安装说明

这条路线不需要付费 Apple Developer Program，但 App 大约每 7 天需要重新签名或刷新一次。

## 1. 在 Codemagic 生成 IPA

1. 打开 Codemagic 的 `photo-practice-ios` 项目。
2. 点击 `Start new build`。
3. 分支选择 `main`。
4. Workflow 选择：`ios-sideloadly-ipa`。
5. 等构建完成。
6. 在 `Artifacts` 下载：`PhotoPractice-unsigned.ipa`。

不要下载 `PhotoPractice.app.zip`，那个是模拟器预览用的，不能直接装到 iPhone。

## 2. 在 Windows 安装 Sideloadly

1. 打开 https://sideloadly.io/
2. 下载 Windows 版 Sideloadly。
3. 按 Sideloadly 提示安装 Apple iTunes / iCloud 组件。
4. 用 USB 连接 iPhone，并在 iPhone 上点击信任这台电脑。

## 3. 用普通 Apple ID 安装

1. 打开 Sideloadly。
2. 把 `PhotoPractice-unsigned.ipa` 拖进去。
3. 选择你的 iPhone。
4. 输入普通 Apple ID。
5. 点击 Start。
6. 如果 Apple 要求验证码，按 Sideloadly 提示输入。

安装后，如果 iPhone 提示不信任开发者：

1. 打开 iPhone 设置。
2. 进入 `通用` -> `VPN 与设备管理`。
3. 找到你的 Apple ID 开发者证书。
4. 点击信任。

## 4. 导入图片包

App 安装后，把本机这个文件放到 iCloud Drive、我的 iPhone 或下载目录：

```text
G:\002 AI\001 project\001 app-design-photo\ios-app\PhotoLibrary.zip
```

然后在 PhotoPractice 中进入 `设置` -> `导入图片压缩包`。

## 限制

- 免费 Apple ID 签名通常 7 天过期。
- 免费账号通常最多同时安装 3 个自签 App。
- 不能用 TestFlight，也不能上架 App Store。
- 到期后用 Sideloadly 重新安装同一个 IPA 即可；保持相同 Bundle ID 和 Apple ID 时，一般会覆盖安装。
