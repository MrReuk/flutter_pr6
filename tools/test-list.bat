@echo off
rem Полный перечень тестов в формате JSON (build\tests.json).
cd /d "%~dp0.."
if not exist build mkdir build
call flutter test --reporter json > build\tests.json 2> build\tests.err
echo test exit code: %errorlevel%
