@echo off

set VCVARS="True"
set TRIAL="True"
set LIBDB="True"

rem parse arguments: [NOVARS] [NOTRIAL] [NODEBUG]
:LOOP
if "%1" == "NOVARS" set VCVARS="False"
if "%1" == "NOTRIAL" set TRIAL="False"
if "%1" == "NODEBUG" set LIBDB="False"
SHIFT
if not "%1" == "" goto LOOP

rem set MSBuild environment variables
if %VCVARS% == "True" (
   pushd
   call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat" x86
   popd
)
pushd

rem generate a pseudo build number
call build_no.bat

rem build the trial program
if %TRIAL% == "True" ( 
   call msbuild.exe .\Trial\slcan_test.vcxproj /t:Clean;Build /p:"Configuration=Debug";"Platform=Win32"
   if errorlevel 1 goto end
)
rem build the SLCAN library (dynamic and static)
call msbuild.exe .\Library\uvslcan.vcxproj /t:Clean;Build /p:"Configuration=Release_dll";"Platform=Win32"
if errorlevel 1 goto end

call msbuild.exe .\Library\uvslcan.vcxproj /t:Clean;Build /p:"Configuration=Release_lib";"Platform=Win32"
if errorlevel 1 goto end

if %LIBDB% == "True" (
   call msbuild.exe .\Library\uvslcan.vcxproj /t:Clean;Build /p:"Configuration=Debug_lib";"Platform=Win32"
   if errorlevel 1 goto end
)
rem copy the arifacts into the Binaries folder
echo Copying artifacts...
set BIN=.\Binaries
if not exist %BIN% mkdir %BIN%
set BIN=%BIN%\x86
if not exist %BIN% mkdir %BIN%
copy /Y .\Library\Release_dll\uvslcan.dll %BIN%
copy /Y .\Library\Release_dll\uvslcan.exp %BIN%
copy /Y .\Library\Release_dll\uvslcan.lib %BIN%
copy /Y .\Library\Release_dll\uvslcan.pdb %BIN%
set BIN=%BIN%\lib
if not exist %BIN% mkdir %BIN%
copy /Y .\Library\Release_lib\uvslcan.lib %BIN%
copy /Y .\Library\Release_lib\uvslcan.pdb %BIN%
echo "Static library (x64)" > %BIN%\readme.txt
set BIN=%BIN%\Debug
if %LIBDB% == "True" (
   if not exist %BIN% mkdir %BIN%
   copy /Y .\Library\Debug_lib\uvslcan.lib %BIN%
   copy /Y .\Library\Debug_lib\uvslcan.pdb %BIN%
   copy /Y .\Library\Debug_lib\uvslcan.idb %BIN%
   echo "Static debug library (x64)" > %BIN%\readme.txt
)
rem copy the header files into the Includes folder
echo Copying header files...
set INC=.\Includes
if not exist %INC% mkdir %INC%
copy /Y .\Sources\slcan.h %INC%
copy /Y .\Sources\serial_attr.h %INC%

rem end of the job
:end
popd
if %VCVARS% == "True" (
   pause
)
