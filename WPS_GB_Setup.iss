; ============================================
; WPS国标公文安装包 - 最终版
; 作者：laogongcn
; GitHub：https://github.com/laogongcn/WPS-GB-Document-Setup
; 博客：https://blog.csdn.net/youngong
; 版本：2.0
; ============================================

[Setup]
AppName=WPS国标公文安装包
AppVersion=2.0
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

; 输出设置
OutputDir=D:\WPS_GB_Setup
OutputBaseFilename=WPS国标公文安装包

; 界面设置
WizardStyle=modern

; 禁用开始菜单文件夹
DisableProgramGroupPage=yes

; 卸载支持
Uninstallable=yes

; 源文件目录
SourceDir=D:\WPS_GB_Setup

; 关闭重启管理器
CloseApplications=no
RestartApplications=no

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
; 字体文件
Source: "FZFS_Document.TTF"; DestDir: "{fonts}"; FontInstall: "方正公文仿宋"; Flags: ignoreversion
Source: "FZHT_Document.TTF"; DestDir: "{fonts}"; FontInstall: "方正公文黑体"; Flags: ignoreversion
Source: "FZKT_Document.TTF"; DestDir: "{fonts}"; FontInstall: "方正公文楷体"; Flags: ignoreversion
Source: "FZXBS_Document.TTF"; DestDir: "{fonts}"; FontInstall: "方正公文小标宋"; Flags: ignoreversion

; WPS 模板文件
Source: "Normal.dotm"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Code]
const
  WM_FONTCHANGE = $001D;

var
  WPSTemplatePath: string;

function GetWPSTemplateDir: string;
var
  Paths: array of string;
  i: Integer;
  UserProfile: string;
begin
  UserProfile := GetEnv('USERPROFILE');
  SetArrayLength(Paths, 5);
  
  Paths[0] := ExpandConstant('{userappdata}\Kingsoft\office6\templates\wps\zh_CN\');
  Paths[1] := ExpandConstant('{userappdata}\Kingsoft\office6\templates\wps\zh_cn\');
  Paths[2] := UserProfile + '\AppData\Roaming\kingsoft\wps\templates\wps\zh_CN\';
  Paths[3] := UserProfile + '\AppData\Roaming\Microsoft\Templates\';
  Paths[4] := ExpandConstant('{localappdata}\Kingsoft\WPS Office\templates\wps\zh_CN\');
  
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

procedure RefreshFonts;
begin
  SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);
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
      FileCopy(TemplateDest, BackupPath, False);
    end;
    FileCopy(TemplateSource, TemplateDest, False);
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
    InstallTemplate;
    RefreshFonts;
    CleanupInstallDir;
  end;
  
  if CurStep = ssDone then
  begin
    MsgBox('安装完成！' #13#13 +
           '方正公文四款字体已安装：' #13 +
           '  ● 方正公文仿宋' #13 +
           '  ● 方正公文黑体' #13 +
           '  ● 方正公文楷体' #13 +
           '  ● 方正公文小标宋' #13#13 +
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
    RefreshFonts;
  end;
end;