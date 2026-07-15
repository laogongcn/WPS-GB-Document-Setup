# WPS国标公文安装包

一键安装国标公文字体 + WPS国标公文模板，基于 GB/T 9704-2012 标准。

## 下载

👉 直接下载：[WPS_GB_Setup_v2.3.exe](https://github.com/laogongcn/WPS-GB-Document-Setup/releases/latest)

## 使用方法

1. 双击 `WPS_GB_Setup_v2.3.exe`
2. 按向导提示完成安装
3. 打开WPS文字即可使用

### 静默安装（企业部署）

```cmd
WPS_GB_Setup_v2.3.exe /VERYSILENT /SUPPRESSMSGBOXES /LOG=install.log
```

## 功能

- 自动安装所有随包的 TrueType/OpenType 字体（通配符扫描，无需硬编码）
- 自动配置WPS国标公文模板（自动备份原模板）
- 支持WPS Office多版本路径检测（office6 ~ office9、专业版）
- 支持控制面板卸载（通过自定义注册表键追踪已安装字体，彻底清理）
- 安装后自动清理临时文件
- GitHub Actions 自动编译发布

## 兼容性

| 项目 | 说明 |
|------|------|
| 操作系统 | Windows 7 / 8 / 10 / 11 |
| WPS版本 | WPS Office 2019 / 2023 / 专业版 |
| 标准依据 | GB/T 9704-2012 党政机关公文格式 |


## 从源码编译

1. 安装 [Inno Setup](https://jrsoftware.org/isinfo.php) 6+
2. 下载 `ChineseSimplified.isl` 放入 Inno Setup 的 `Languages` 文件夹
3. 打开 `WPS_GB_Setup.iss`，按 F7 编译
4. 编译产物位于 `Output\` 目录

> ⚠️ 编辑 `.iss` 文件后请**另存为 ANSI 编码**，否则中文会显示为乱码。

## 目录结构

```
├── WPS_GB_Setup.iss           # Inno Setup 安装脚本
├── *.TTF                     # 国标公文字体文件
├── Normal.dotm                # WPS 国标公文模板
├── .github/workflows/build.yml # GitHub Actions CI/CD
├── CHANGELOG.md
└── README.md
```

## 技术细节

安装脚本特点：

- **通用字体安装**：`[Files]` 段使用 `*.ttf` / `*.otf` 通配符，任何放入安装包目录的字体文件都会被自动安装，无需修改脚本
- **FontCache 自动化**：字体文件直接复制到系统字体目录，由 Windows FontCache 服务自动完成注册和注册表同步，无需手动调用 Win32 API（避免 Win11 死锁）
- **卸载追踪**：安装时记录字体列表到 `HKLM\SOFTWARE\WPS国标公文安装包\InstalledFonts`，卸载时精准清除

## 作者

**laogongcn**

- GitHub: [@laogongcn](https://github.com/laogongcn)
- 博客: https://blog.csdn.net/youngong

## 许可证

MIT
