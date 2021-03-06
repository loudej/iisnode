@echo off
setlocal

set appcmd=%systemroot%\system32\inetsrv\appcmd.exe
set iisnode=%~dp0iisnode.dll
set www=%~dp0www
set index=%www%\index.htm
set schema=%~dp0\iisnode_schema.xml
set addsection=%~dp0\addiisnodesectiongroup.js
set siteName=Default Web Site
set path=node
set site="%siteName%/%path%"
set node=%systemdrive%\node\node.exe
set processor_architecture_flag=%~dp0%PROCESSOR_ARCHITECTURE%.txt
set icacls=%systemdrive%\windows\system32\icacls.exe
set wscript=%systemdrive%\windows\system32\wscript.exe

echo IIS module installer for iisnode - hosting of node.js applications in IIS.
echo This script must be run with administrative privileges.

if not exist "%icacls%" (
	echo Installation failed. The icacls.exe not found at %icacls%. 
	exit /b -1
)

if not exist %appcmd% (
	echo Installation failed. The appcmd.exe IIS management tool was not found at %appcmd%. Make sure you have both IIS7 as well as IIS7 Management Tools installed.
	exit /b -1
)

if not exist "%iisnode%" (
	echo Installation failed. The iisnode.dll native module to install was not found at %iisnode%. Make sure you are running this script from the pre-built installation package rather than from the source tree.
	exit /b -1
)

if not exist "%index%" (
	echo Installation failed. The samples were not found at %www%. Make sure you are running this script from the pre-built installation package rather than from the source tree.
	exit /b -1
)

if not exist "%schema%" (
	echo Installation failed. The configuration schema was not found at %schema%. Make sure you are running this script from the pre-built installation package rather than from the source tree.
	exit /b -1
)

if not exist "%addsection%" (
	echo Installation failed. The %addsection% script required to install iisnode configuration not found. Make sure you are running this script from the pre-built installation package rather than from the source tree.
	exit /b -1
)

if not exist "%processor_architecture_flag%" (
	echo Installation failed. This is a binary build with bitness incompatible with the bitness of your operating system. Please use %PROCESSOR_ARCHITECTURE% build instead. You can get it from https://github.com/tjanczuk/iisnode/archives/master or build yourself.
	exit /b -1
)

if not exist "%node%" (
	echo *****************************************************************************
	echo **************************       ERROR      *********************************
	echo   The node.exe is not found at %node%.
	echo   IIS cannot serve node.js applications without node.exe.
	echo   Please get the latest node.exe build from http://nodejs.org and 
	echo   install it to %node%, then restart the installer 
	echo *****************************************************************************
	echo *****************************************************************************
	exit /b -1
)

if "%1" neq "/s" (
	echo This installer will perform the following tasks:
	echo * ensure that the IIS_IUSRS group has read and execute rights to %node%
	echo * unregister existing "iisnode" global module from your installation of IIS if such registration exists
	echo * register %iisnode% as a native module with your installation of IIS
	echo * install configuration schema for the "iisnode" module
	echo * remove existing "iisnode" section from system.webServer section group in applicationHost.config
	echo * add the "iisnode" section within the system.webServer section group in applicationHost.config
	echo * delete the %site% web application if it exists
	echo * add a new site %site% to IIS with physical path pointing to %www%
	echo This script does not provide means to revert these actions. If something fails in the middle you are on your own.
	echo Press ENTER to continue or Ctrl-C to terminate.
	pause 
)

echo Ensuring IIS_IUSRS group has read and execute rights to %node%...
%icacls% "%node%" /grant IIS_IUSRS:rx
if %ERRORLEVEL% neq 0 (
	echo Installation failed. Cannot set read and execute permissions to %node%. 
	exit /b -1
)
echo ...success

echo Ensuring any existing registration of 'iisnode' native module is removed...
%appcmd% uninstall module iisnode /commit:apphost
if %ERRORLEVEL% neq 0 if %ERRORLEVEL% neq 1168 (
	echo Installation failed. Cannot remove potentially existing registration of 'iisnode' IIS native module
	exit /b -1
)
echo ...success

echo Registering the iisnode native module %iisnode%...
%appcmd% install module /name:iisnode /image:"%iisnode%" /commit:apphost
if %ERRORLEVEL% neq 0 (
	echo Installation failed. Cannot register iisnode native module 
	exit /b -1
)
echo ...success

echo Installing the iisnode module configuration schema from %schema%...
copy /y "%schema%" %systemroot%\system32\inetsrv\config\schema
if %ERRORLEVEL% neq 0 (
	echo Installation failed. Cannot install iisnode module configuration schema
	exit /b -1
)
echo ...success

echo Registering the iisnode section within the system.webServer section group...
"%wscript%" /B /E:jscript "%addsection%"
if %ERRORLEVEL% neq 0 (
	echo Installation failed. Cannot register iisnode configuration section
	exit /b -1
)
echo ...success

echo Ensuring the %site% is removed if it exists...
%appcmd% delete app %site%
if %ERRORLEVEL% neq 0 if %ERRORLEVEL% neq 50 (
	echo Installation failed. Cannot ensure site %site% is removed
	exit /b -1
)
echo ...success

echo Creating IIS site %site% with node.js samples...
%appcmd% add app /site.name:"%siteName%" /path:/%path% /physicalPath:"%www%"
if %ERRORLEVEL% neq 0 (
	echo Installation failed. Cannot create samples site %site% at physical path %www%
	exit /b -1
)
echo ...success

echo INSTALLATION SUCCESSFUL. Check out the samples at http://localhost/node.

endlocal
