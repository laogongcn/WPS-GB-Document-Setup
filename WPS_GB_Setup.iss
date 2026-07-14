; ============================================
; WPS国标公文安装包 - 安装脚本
; 作者：laogongcn
; GitHub：https://github.com/laogongcn/WPS-GB-Document-Setup
; 博客：https://blog.csdn.net/youngong
; 版本：2.1
;
; 注意：本文件必须保存为 ANSI (GBK) 编码
; 如果中文显示乱码，请用记事本另存为 ANSI 编码
; ============================================

[Setup]
AppName=WPS国标公文安装包
AppVersion=2.1
VersionInfoVersion=2.1.0.0
VersionInfoProductVersion=2.1.0.0
AppPublisher=laogongcn
AppPublisherURL=https://github.com/laogongcn/WPS-GB-Document-Setup
AppCopyright=Copyright (C) 2026 laogongcn

; 安装目录（临时目录，安装后自动删除）
DefaultDirName={localappdata}\Temp\WPS_GB_Install
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
OutputBaseFilename=WPS_GB_Setup_v2.2

; 界面设置
WizardStyle=modern

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

var
  WPSTemplatePath: string;

function AddFontResource(lpszFilename: AnsiString): Integer;
  external 'AddFontResourceA@GDI32.dll stdcall';

function RemoveFontResource(lpszFilename: AnsiString): Integer;
  external 'RemoveFontResourceA@GDI32.dll stdcall';

// 从文件名推测注册表用的字体名称
function GuessFontRegName(const FileName: string): string;
var
  NameOnly: string;
begin
  NameOnly := FileName;
  // 去掉扩展名
  if Pos('.', NameOnly) > 0 then
    NameOnly := Copy(NameOnly, 1, Pos('.', NameOnly) - 1);
  // 替换常见后缀和分隔符（Inno Setup 用 StringChange，非 Delphi 的 StringReplace）
  StringChange(NameOnly, '_Document', '');
  StringChange(NameOnly, '_', ' ');
  StringChange(NameOnly, '-', ' ');
  Result := Trim(NameOnly) + ' (TrueType)';
end;

// 安装所有字体
procedure InstallFonts;
var
  FindRec: TFindRec;
  FontSrcPath, FontDestPath, FontRegName: string;
  FontIndex: Integer;
begin
  FontIndex := 0;

  // 处理 .ttf 文件
  if FindFirst(ExpandConstant('{tmp}\Fonts\*.ttf'), FindRec) then
  begin
    try
      repeat
        FontSrcPath := ExpandConstant('{tmp}\Fonts\') + FindRec.Name;
        FontDestPath := ExpandConstant('{fonts}\') + FindRec.Name;

        // 复制到系统字体目录
        if not CopyFile(FontSrcPath, FontDestPath, False) then
        begin
          // 如果文件已存在，强制覆盖
          CopyFile(FontSrcPath, FontDestPath, True);
        end;

        // 注册字体
        AddFontResource(FontDestPath);

        // 写注册表持久化
        FontRegName := GuessFontRegName(FindRec.Name);
        RegWriteStringValue(
          HKLM,
          'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
          FontRegName,
          FindRec.Name
        );

        // 记录已安装的字体（用于卸载）
        RegWriteStringValue(
          HKLM,
          InstalledFontsKey,
          'Font_' + IntToStr(FontIndex),
          FindRec.Name
        );
        FontIndex := FontIndex + 1;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;

  // 处理 .otf 文件
  if FindFirst(ExpandConstant('{tmp}\Fonts\*.otf'), FindRec) then
  begin
    try
      repeat
        FontSrcPath := ExpandConstant('{tmp}\Fonts\') + FindRec.Name;
        FontDestPath := ExpandConstant('{fonts}\') + FindRec.Name;

        if not CopyFile(FontSrcPath, FontDestPath, False) then
          CopyFile(FontSrcPath, FontDestPath, True);

        AddFontResource(FontDestPath);

        FontRegName := GuessFontRegName(FindRec.Name);
        RegWriteStringValue(
          HKLM,
          'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
          FontRegName,
          FindRec.Name
        );

        RegWriteStringValue(
          HKLM,
          InstalledFontsKey,
          'Font_' + IntToStr(FontIndex),
          FindRec.Name
        );
        FontIndex := FontIndex + 1;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;

  // 记录安装数量
  RegWriteDWordValue(HKLM, InstalledFontsKey, 'FontCount', FontIndex);
end;

// 卸载所有由本安装包安装的字体
procedure UninstallFonts;
var
  FontCount: Cardinal;
  i: Integer;
  FontFile, FontPath, FontRegName: string;
begin
  if not RegQueryDWordValue(HKLM, InstalledFontsKey, 'FontCount', FontCount) then
    Exit;

  for i := 0 to FontCount - 1 do
  begin
    if RegQueryStringValue(HKLM, InstalledFontsKey, 'Font_' + IntToStr(i), FontFile) then
    begin
      FontPath := ExpandConstant('{fonts}\') + FontFile;
      FontRegName := GuessFontRegName(FontFile);

      // 取消注册
      RemoveFontResource(FontPath);

      // 删除文件
      DeleteFile(FontPath);

      // 清理注册表
      RegDeleteValue(
        HKLM,
        'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
        FontRegName
      );
    end;
  end;

  // 清理自己的记录
  RegDeleteKeyIncludingSubkeys(HKLM, InstalledFontsKey);
end;

procedure RefreshFonts;
begin
  SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
end;

function GetWPSTemplateDir: string;
var
  Paths: array of string;
  i: Integer;
  UserProfile: string;
begin
  UserProfile := GetEnv('USERPROFILE');
  // 支持 WPS Office 多版本，涵盖 office6 ~ office9 及专业版
  SetArrayLength(Paths, 7);

  Paths[0] := ExpandConstant('{userappdata}\Kingsoft\office6\templates\wps\zh_CN\');
  Paths[1] := ExpandConstant('{userappdata}\Kingsoft\office7\templates\wps\zh_CN\');
  Paths[2] := ExpandConstant('{userappdata}\Kingsoft\office8\templates\wps\zh_CN\');
  Paths[3] := ExpandConstant('{userappdata}\Kingsoft\office9\templates\wps\zh_CN\');
  Paths[4] := ExpandConstant('{userappdata}\Kingsoft\WPS Office\templates\wps\zh_CN\');
  Paths[5] := ExpandConstant('{localappdata}\Kingsoft\WPS Office\templates\wps\zh_CN\');
  Paths[6] := UserProfile + '\AppData\Roaming\Microsoft\Templates\';

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
      BackupPath := WPSTemplatePath + 'Normal.dotm.backup_' +
                    GetDateTimeString('yyyy-mm-dd_hh-nn-ss', '-', ':');
      CopyFile(TemplateDest, BackupPath, False);
    end;
    CopyFile(TemplateSource, TemplateDest, False);
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
begin
  if CurUninstallStep = usUninstall then
  begin
    UninstallFonts;
    RefreshFonts;
  end;
end;
