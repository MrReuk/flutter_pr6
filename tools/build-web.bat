@echo off
rem Production build (GitHub Actions does the same).
rem   tools\build-web.bat [base-href] [API url]
rem Example for a project on GitHub Pages:
rem   tools\build-web.bat /flutter_pr6/ https://api.example.com/api
rem Result: build\web (index.html is also copied to 404.html).
setlocal
cd /d "%~dp0.."
set "BASE=%~1"
if "%BASE%"=="" set "BASE=/"
set "API=%~2"
call flutter pub get
call flutter build web --release --wasm --base-href "%BASE%" --dart-define=API_BASE_URL=%API%
if errorlevel 1 exit /b 1
rem GitHub Pages does not know the app routes and answers 404.html for them.
copy /Y build\web\index.html build\web\404.html >nul
echo.
echo Done: build\web. Check it the way Pages serves it:
echo   node tools\serve-build.js build\web --base %BASE% --port 8000
