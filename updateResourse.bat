@echo off&color 17

::获取管理员权限，如果MAA不是管理员权限，可删除以下代码
if exist "%SystemRoot%\SysWOW64" path %path%;%windir%\SysNative;%SystemRoot%\SysWOW64;%~dp0

bcdedit >nul

if '%errorlevel%' NEQ '0' (goto UACPrompt) else (goto UACAdmin)

:UACPrompt

%1 start "" mshta vbscript:createobject("shell.application").shellexecute("""%~0""","::",,"runas",1)(window.close)&exit

exit /B

:UACAdmin

cd /d "%~dp0"

echo 当前运行路径是：%CD%

echo 已获取管理员权限

@chcp 65001 > nul
:: 初始化变量，默认不执行复制
set DoCopy=0

:: 检查当前目录下是否存在 "MAA.exe" 文件
if not exist MAA.exe (
    echo "错误：当前目录下未找到 MAA.exe 文件。"
    echo "请将本脚本放到MAA.exe同级目录下!"
    powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $notify = New-Object system.windows.forms.notifyicon; $notify.icon = [System.Drawing.SystemIcons]::Information; $notify.visible = $true; $notify.showballoontip(0, '位置错误', '请将本脚本放到MAA.exe同级目录下!', [system.windows.forms.tooltipicon]::Info)"
    exit /b
)

:: 检测当前路径下是否有 MaaResource 文件夹
if not exist MaaResource (
    echo "MaaResource 文件夹不存在，正在创建并初始化..."
    powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $notify = New-Object system.windows.forms.notifyicon; $notify.icon = [System.Drawing.SystemIcons]::Information; $notify.visible = $true; $notify.showballoontip(0, '资源更新', '正在自动更新资源……', [system.windows.forms.tooltipicon]::Info)"
    mkdir MaaResource
    cd MaaResource
    git init
    git remote add origin https://github.com/MaaAssistantArknights/MaaResource.git
    git pull origin main
    set DoCopy=1
) else (
    echo "MaaResource 文件夹已存在，正在检查更新..."
    cd MaaResource
    git fetch origin main
    git diff --quiet --exit-code master origin/main > nul 
    if errorlevel 1 (
        echo "有更新，正在拉取最新代码..."
        powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $notify = New-Object system.windows.forms.notifyicon; $notify.icon = [System.Drawing.SystemIcons]::Information; $notify.visible = $true; $notify.showballoontip(0, '资源更新', '正在自动更新资源……', [system.windows.forms.tooltipicon]::Info)"
        git merge FETCH_HEAD
        set DoCopy=1
    ) else (
        echo "已是最新版本，无需更新。"
    )
)
:: 返回上一级文件夹
cd ..

:: 根据变量DoCopy的值决定是否执行复制操作
if %DoCopy%==1 (
    echo "正在复制 cache 和 resource 文件夹到当前路径..."
    xcopy /E /I /Y .\MaaResource  . > nul
) else (
    echo "跳过复制操作。"
)



if %DoCopy%==1 (
    echo "检查是否有正在运行的 MAA.exe..."
    powershell -Command "Get-Process | Where-Object { $_.Name -eq 'MAA' } | ForEach-Object { Stop-Process -Id $_.Id -Force }"
    if %errorlevel% equ 0 (
        echo "MAA.exe 已被关闭，正在重新启动..."
        start .\MAA.exe
        powershell -Command "Start-Sleep 2;Add-Type -AssemblyName System.Windows.Forms; $notify = New-Object system.windows.forms.notifyicon; $notify.icon = [System.Drawing.SystemIcons]::Information; $notify.visible = $true; $notify.showballoontip(0, '更新完成', '资源已更新！', [system.windows.forms.tooltipicon]::Info)"
        exit /b
    )
)




@REM timeout /t 100 > nul

endlocal