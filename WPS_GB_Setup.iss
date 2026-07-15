; ============================================
; WPS国标公文安装包 - 安装脚本
; 作者：laogongcn
; GitHub：https://github.com/laogongcn/WPS-GB-Document-Setup
; 博客：https://blog.csdn.net/youngong
; 版本：2.3
;
; 注意：本文件必须保存为 ANSI (GBK) 编码
; 如果中文显示乱码，请用记事本另存为 ANSI 编码
; ============================================

[Setup]
AppName=WPS国标公文安装包
AppVersion=2.3
VersionInfoVersion=2.3.0.0
VersionInfoProductVersion=2.3.0.0
AppPublisher=laogongcn
AppPublisherURL=https://github.com/laogongcn/WPS-GB-Document-Setup
AppCopyright=Copyright (C) 2026 laogongcn

; 安装目录（临时目录，安装后自动删除）
; 使用 {commonappdata} 避免 admin 模式下的每用户区域警告
DefaultDirName={commonappdata}\WPS_GB_Install
DefaultGroupName=WPS国标公文包
UninstallDisplayIcon={app}\WPS国标公文安装包.exe
UninstallDisplayName=WPS国标公文安装包

; 压缩设置
Compression=lzma2/ultra
SolidCompression=yes

; 权限和日志
PrivilegesRequired=admin
SetupLogging=yes

; 输出设置（使用相对路径，可跨机器编译）
OutputDir=.\Output
OutputBaseFilename=WPS_GB_Setup_v2.3

; 界面设置
WizardStyle=modern

; 禁用安装目录选择（字体/模板均有固定位置，只需临时文件夹）
DisableDirPage=yes
; 禁用开始菜单文件夹
DisableProgramGroupPage=yes

; 卸载支持
Uninstallable=yes

; 源文件目录：不设置 SourceDir，编译器默认使用本 .iss 脚本所在目录
; （{src} 是运行期常量，不能用于编译期 SourceDir 指令）

; 关闭重启管理器
CloseApplications=no
RestartApplications=no

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; 自动安装所有随包的 TTF/OTF 字体文件（通用型）
; 不直接用 FontInstall 以支持动态批量安装
Source: "*.ttf"; DestDir: "{tmp}\Fonts"; Flags: ignoreversion
Source: "*.otf"; DestDir: "{tmp}\Fonts"; Flags: ignoreversion skipifsourcedoesntexist

; WPS 模板文件（先解压到临时目录，安装完毕后自动删除）
Source: "Normal.dotm"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Code]
const
  WM_FONTCHANGE = $001D;

  // 自定义注册表路径，用于记录已安装的字体（卸载时清理）
  InstalledFontsKey = 'SOFTWARE\WPS国标公文安装包\InstalledFonts';
  AppRegKey = 'SOFTWARE\WPS国标公文安装包';

var
  WPSTemplatePath: string;

// 安装所有字体（Win11 兼容版）
// 原理：只需复制到 %windir%\Fonts，Windows FontCache 服务会自动完成注册
// 不调用 AddFontResource / 不写 HKLMFonts 注册表 ——
//   避免与 FontCache3.0.0.0 服务冲突导致卡死
procedure InstallFonts;
var
  FindRec: TFindRec;
  FontSrcPath, FontDestPath: string;
  FontIndex: Integer;
begin
  FontIndex := 0;

  // 通装 .ttf
  if FindFirst(ExpandConstant('{tmp}\Fonts\*.ttf'), FindRec) then
  begin
    try
      repeat
        Log('InstallFonts: copying ' + FindRec.Name);
        FontSrcPath := ExpandConstant('{tmp}\Fonts\') + FindRec.Name;
        FontDestPath := ExpandConstant('{fonts}\') + FindRec.Name;

        if not CopyFile(FontSrcPath, FontDestPath, False) then
          CopyFile(FontSrcPath, FontDestPath, True);

        // 记录已安装的字体（仅存我们自己的跟踪键，用于卸载清理）
        RegWriteStringValue(HKLM, InstalledFontsKey,
          'Font_' + IntToStr(FontIndex), FindRec.Name);
        FontIndex := FontIndex + 1;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;

  // 通装 .otf
  if FindFirst(ExpandConstant('{tmp}\Fonts\*.otf'), FindRec) then
  begin
    try
      repeat
        Log('InstallFonts: copying ' + FindRec.Name);
        FontSrcPath := ExpandConstant('{tmp}\Fonts\') + FindRec.Name;
        FontDestPath := ExpandConstant('{fonts}\') + FindRec.Name;

        if not CopyFile(FontSrcPath, FontDestPath, False) then
          CopyFile(FontSrcPath, FontDestPath, True);

        RegWriteStringValue(HKLM, InstalledFontsKey,
          'Font_' + IntToStr(FontIndex), FindRec.Name);
        FontIndex := FontIndex + 1;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;

  RegWriteDWordValue(HKLM, InstalledFontsKey, 'FontCount', FontIndex);
end;

// 卸载所有由本安装包安装的字体（Win11 兼容版）
// 仅删除文件 + 清理跟踪键；FontCache 服务自动同步注册表
procedure UninstallFonts;
var
  FontCount: Cardinal;
  i: Integer;
  FontFile, FontPath: string;
begin
  if not RegQueryDWordValue(HKLM, InstalledFontsKey, 'FontCount', FontCount) then
    Exit;

  for i := 0 to FontCount - 1 do
  begin
    if RegQueryStringValue(HKLM, InstalledFontsKey, 'Font_' + IntToStr(i), FontFile) then
    begin
      FontPath := ExpandConstant('{fonts}\') + FontFile;
      Log('UninstallFonts: removing ' + FontFile);

      // 直接删除字体文件（Windows FontCache 服务自动取消注册）
      DeleteFile(FontPath);
    end;
  end;

  // 清理自己的记录
  RegDeleteKeyIncludingSubkeys(HKLM, InstalledFontsKey);
end;

procedure RefreshFonts;
begin
  // 用 PostMessage（异步，立即返回）替代 SendMessage（同步，会等待每个窗口响应）
  // Win11 下 SendMessage(HWND_BROADCAST, WM_FONTCHANGE) 可能被 FontCache 服务
  // 或某个窗口阻塞，导致安装进程卡在 70% 无响应。PostMessage 不等待，避免挂起。
  PostMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
end;

function GetWPSTemplateDir: string;
var
  Paths: array of string;
  i: Integer;
  AppData, LocalAppData: string;
begin
  // 用环境变量替代每用户常量，避免 admin 模式 UsedUserAreasWarning
  AppData := GetEnv('APPDATA');
  if AppData = '' then
    AppData := GetEnv('USERPROFILE') + '\AppData\Roaming';
  LocalAppData := GetEnv('LOCALAPPDATA');
  if LocalAppData = '' then
    LocalAppData := GetEnv('USERPROFILE') + '\AppData\Local';

  // 支持 WPS Office 多版本，涵盖 office6 ~ office9 及专业版
  SetArrayLength(Paths, 8);

  Paths[0] := AppData + '\Kingsoft\office6\templates\wps\zh_CN\';
  Paths[1] := AppData + '\Kingsoft\office7\templates\wps\zh_CN\';
  Paths[2] := AppData + '\Kingsoft\office8\templates\wps\zh_CN\';
  Paths[3] := AppData + '\Kingsoft\office9\templates\wps\zh_CN\';
  Paths[4] := AppData + '\Kingsoft\WPS Office\templates\wps\zh_CN\';
  Paths[5] := LocalAppData + '\Kingsoft\WPS Office\templates\wps\zh_CN\';
  Paths[6] := AppData + '\Microsoft\Templates\';
  // 兜底：确保至少有一条能写入
  Paths[7] := AppData + '\Kingsoft\office6\templates\wps\zh_CN\';

  Result := Paths[0];
  for i := 0 to GetArrayLength(Paths) - 1 do
  begin
    if DirExists(Paths[i]) then
    begin
      Result := Paths[i];
      Exit;
    end;
  end;

  ForceDirectories(Result);
end;

procedure InstallTemplate;
var
  TemplateSource, TemplateDest, BackupPath: string;
begin
  WPSTemplatePath := GetWPSTemplateDir;
  TemplateSource := ExpandConstant('{tmp}\Normal.dotm');
  TemplateDest := WPSTemplatePath + 'Normal.dotm';

  if FileExists(TemplateSource) then
  begin
    if FileExists(TemplateDest) then
    begin
      // 备份原有模板（卸载时自动恢复）
      BackupPath := WPSTemplatePath + 'Normal.dotm.backup_' +
                    GetDateTimeString('yyyy-mm-dd_hh-nn-ss', '-', ':');
      CopyFile(TemplateDest, BackupPath, False);
      Log('InstallTemplate: backed up to ' + BackupPath);

      // 记录到注册表，卸载时据此恢复
      RegWriteStringValue(HKLM, AppRegKey, 'TemplateDest', TemplateDest);
      RegWriteStringValue(HKLM, AppRegKey, 'TemplateBackup', BackupPath);
    end
    else
    begin
      // 之前没有模板，记录目标路径（卸载时直接删除即可）
      RegWriteStringValue(HKLM, AppRegKey, 'TemplateDest', TemplateDest);
      RegDeleteValue(HKLM, AppRegKey, 'TemplateBackup');
    end;

    CopyFile(TemplateSource, TemplateDest, False);
    Log('InstallTemplate: installed to ' + TemplateDest);
  end;
end;

procedure CleanupInstallDir;
begin
  DelTree(ExpandConstant('{app}'), True, True, True);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    InstallFonts;
    InstallTemplate;
    RefreshFonts;
    CleanupInstallDir;
  end;

  if CurStep = ssDone then
  begin
    MsgBox('安装完成！' #13#13 +
           '所有随包字体已安装。' #13#13 +
           'WPS国标公文模板已配置。' #13#13 +
           '请打开WPS文字使用。' #13#13 +
           '项目主页：' #13 +
           'https://github.com/laogongcn/WPS-GB-Document-Setup' #13#13 +
           '技术博客：' #13 +
           'https://blog.csdn.net/youngong',
           mbInformation, MB_OK);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  TemplateDest, BackupPath: string;
begin
  if CurUninstallStep = usUninstall then
  begin
    // 1. 恢复/删除模板
    if RegQueryStringValue(HKLM, AppRegKey, 'TemplateDest', TemplateDest) then
    begin
      if RegQueryStringValue(HKLM, AppRegKey, 'TemplateBackup', BackupPath) and
         FileExists(BackupPath) then
      begin
        // 有备份 → 恢复原有模板
        CopyFile(BackupPath, TemplateDest, False);
        DeleteFile(BackupPath);
        Log('Uninstall: restored original template from ' + BackupPath);
      end
      else
      begin
        // 无备份 → 之前就没有模板，直接删除我们的
        DeleteFile(TemplateDest);
        Log('Uninstall: removed template ' + TemplateDest);
      end;
    end;

    // 2. 卸载字体
    UninstallFonts;
    RefreshFonts;

    // 3. 清理注册表记录
    RegDeleteKeyIncludingSubkeys(HKLM, AppRegKey);
  end;
end;
