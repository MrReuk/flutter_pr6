@echo off
rem Four builds for the size table. Result: build\size-report.md,
rem full build output: measure.log.
rem   js-before    regular build, all screens in the main file
rem   js-after     screens are loaded on demand (deferred)
rem   wasm-before  the same with --wasm
rem   wasm-after   the same with --wasm
rem "before" is built from a temporary copy of the project with plain imports
rem (tools\make_eager.dart); the app source code is not changed.
rem   tools\measure-builds.bat [API url]
setlocal
cd /d "%~dp0.."
set "ROOT=%CD%"
set "LOG=%ROOT%\measure.log"
set "OUT=%ROOT%\build\size"
set "EAGER=%TEMP%\library_eager_src"
set "API=%~1"
if "%API%"=="" set "API=http://localhost:8080/api"

echo === start === > "%LOG%"
call flutter pub get >> "%LOG%" 2>&1
if exist "%OUT%" rmdir /s /q "%OUT%"
mkdir "%OUT%"

call :build js-after "%ROOT%" ""
call :build wasm-after "%ROOT%" "--wasm"

if exist "%EAGER%" rmdir /s /q "%EAGER%"
robocopy "%ROOT%" "%EAGER%" /E /XD build .dart_tool .git .idea /NFL /NDL /NJH /NJS >nul
call dart run tools\make_eager.dart "%ROOT%\lib\lazy_screens.dart" "%EAGER%\lib\lazy_screens.dart" >> "%LOG%" 2>&1
pushd "%EAGER%"
call flutter pub get >> "%LOG%" 2>&1
popd
call :build js-before "%EAGER%" ""
call :build wasm-before "%EAGER%" "--wasm"

call dart run tools\measure_size.dart "%OUT%" "%ROOT%\build\size-report.md" >> "%LOG%" 2>&1
type "%ROOT%\build\size-report.md"
echo === finished === >> "%LOG%"
exit /b 0

:build
rem %1 name, %2 project folder, %3 flag --wasm or empty
echo === %~1 === >> "%LOG%"
if exist "%~2\build\web" rmdir /s /q "%~2\build\web"
pushd "%~2"
call flutter build web --release %~3 --dart-define=API_BASE_URL=%API% >> "%LOG%" 2>&1
popd
robocopy "%~2\build\web" "%OUT%\%~1" /E /NFL /NDL /NJH /NJS >nul
exit /b 0
