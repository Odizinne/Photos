#define AppName       "Photos"
#define AppSourceDir  "..\build\Photos\"
#define AppExeName    "Photos.exe"
#define                MajorVersion    
#define                MinorVersion    
#define                RevisionVersion    
#define                BuildVersion    
#define TempVersion    GetVersionComponents(AppSourceDir + "bin\" + AppExeName, MajorVersion, MinorVersion, RevisionVersion, BuildVersion)
#define AppVersion     str(MajorVersion) + "." + str(MinorVersion) + "." + str(RevisionVersion)
#define AppPublisher  "Odizinne"
#define AppURL        "https://github.com/Odizinne/Photos"
#define AppIcon       "..\Resources\icons\icon.ico"
#define CurrentYear   GetDateTimeString('yyyy','','')

[Setup]
AppId={{99888fa8-8159-47d8-b610-6d3f80b5ae16}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}

VersionInfoDescription={#AppName} installer
VersionInfoProductName={#AppName}
VersionInfoVersion={#AppVersion}

AppCopyright=(c) {#CurrentYear} {#AppPublisher}

UninstallDisplayName={#AppName} {#AppVersion}
UninstallDisplayIcon={app}\bin\{#AppExeName}
AppPublisher={#AppPublisher}

AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}

ShowLanguageDialog=yes
UsePreviousLanguage=no
LanguageDetectionMethod=uilanguage

WizardStyle=modern

DisableProgramGroupPage=yes
DisableWelcomePage=yes

SetupIconFile={#AppIcon}

DefaultGroupName={#AppName}
DefaultDirName={localappdata}\Programs\{#AppName}

PrivilegesRequired=lowest
OutputBaseFilename=Photos_installer
Compression=lzma
SolidCompression=yes
UsedUserAreasWarning=no

[Languages]
Name: "english";    MessagesFile: "compiler:Default.isl"
Name: "french";     MessagesFile: "compiler:Languages\French.isl"
Name: "german";     MessagesFile: "compiler:Languages\German.isl"
Name: "italian";    MessagesFile: "compiler:Languages\Italian.isl"
Name: "korean";     MessagesFile: "compiler:Languages\Korean.isl"
Name: "russian";    MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "registerfiles"; Description: "Register Photos as default image viewer"; GroupDescription: "File associations"; Flags: checkedonce

[Files]
Source: "{#AppSourceDir}*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
; Register the application
Root: HKCU; Subkey: "Software\Classes\Applications\Photos.exe"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\Photos.exe\shell"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\Photos.exe\shell\open"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Applications\Photos.exe\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

; Register file associations for common image formats
Root: HKCU; Subkey: "Software\Classes\.jpg\OpenWithProgids"; ValueType: string; ValueName: "Photos.jpg"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.jpeg\OpenWithProgids"; ValueType: string; ValueName: "Photos.jpeg"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.png\OpenWithProgids"; ValueType: string; ValueName: "Photos.png"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.gif\OpenWithProgids"; ValueType: string; ValueName: "Photos.gif"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.bmp\OpenWithProgids"; ValueType: string; ValueName: "Photos.bmp"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.tiff\OpenWithProgids"; ValueType: string; ValueName: "Photos.tiff"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.tif\OpenWithProgids"; ValueType: string; ValueName: "Photos.tif"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.webp\OpenWithProgids"; ValueType: string; ValueName: "Photos.webp"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\.svg\OpenWithProgids"; ValueType: string; ValueName: "Photos.svg"; ValueData: ""; Flags: uninsdeletevalue; Tasks: registerfiles

; Create ProgID entries for each format
Root: HKCU; Subkey: "Software\Classes\Photos.jpg"; ValueType: string; ValueData: "JPEG Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.jpg\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.jpg\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\Photos.jpeg"; ValueType: string; ValueData: "JPEG Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.jpeg\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.jpeg\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\Photos.png"; ValueType: string; ValueData: "PNG Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.png\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.png\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\Photos.gif"; ValueType: string; ValueData: "GIF Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.gif\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.gif\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\Photos.bmp"; ValueType: string; ValueData: "Bitmap Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.bmp\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.bmp\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\Photos.tiff"; ValueType: string; ValueData: "TIFF Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.tiff\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.tiff\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\Photos.tif"; ValueType: string; ValueData: "TIFF Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.tif\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.tif\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\Photos.webp"; ValueType: string; ValueData: "WebP Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.webp\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.webp\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

Root: HKCU; Subkey: "Software\Classes\Photos.svg"; ValueType: string; ValueData: "SVG Image"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.svg\DefaultIcon"; ValueType: string; ValueData: """{app}\bin\Photos.exe"",0"; Flags: uninsdeletekey; Tasks: registerfiles
Root: HKCU; Subkey: "Software\Classes\Photos.svg\shell\open\command"; ValueType: string; ValueData: """{app}\bin\Photos.exe"" ""%1"""; Flags: uninsdeletekey; Tasks: registerfiles

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\bin\{#AppExeName}"; IconFilename: "{app}\bin\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\bin\{#AppExeName}"; Tasks: desktopicon; IconFilename: "{app}\bin\{#AppExeName}"

[Run]
Filename: "{app}\bin\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall