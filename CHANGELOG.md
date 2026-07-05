# 更新日志

## [2.2] - 2026-07-05

### 重构

- 字体安装改为通配符批量扫描，支持任意 .ttf / .otf 自动安装，无需硬编码
- 使用 Win32 API `AddFontResourceA` / `RemoveFontResourceA` 注册/注销字体
- 通过自定义注册表键 `HKLM\SOFTWARE\WPS国标公文安装包\InstalledFonts` 追踪字体，卸载时精准清理
- 新增 OTF 字体支持（.otf 文件同样自动安装）

### 修复

- 修复脚本中所有中文乱码
- `SourceDir` 改为 `{src}`，`OutputDir` 改为 `.\Output`，消除硬编码绝对路径
- WPS 模板路径扩展到 office6 ~ office9 及专业版

### 新增

- 新增 GitHub Actions CI/CD 自动编译
- README 添加静默安装命令、兼容性表、技术细节说明
- `.gitignore` 添加 `/Output/` 忽略规则

## [2.1] - 2026-06-12

### 更新

- 更新 Normal.dotm 模板
- 安装包文件名改为英文命名（WPS_GB_Setup_v2.1.exe）
- 修正脚本源文件路径

## [2.0] - 2026-05-11

### 新增

- 首次正式发布
- 支持公文字体自动安装
- 支持WPS多版本模板路径自动检测
- 支持简体中文界面
- 支持控制面板卸载
- 安装后自动清理临时文件
