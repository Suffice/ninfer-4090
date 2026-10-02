@echo off
rem build-v120.bat - full rebuild of ninfer-serve.exe after the v1.2.0 upstream merge.
rem (build-v2.bat builds only the materialization test target; this one builds the server app.)
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
cmake --build C:\Users\Morawake\ninfer-4090\build-ninja --target ninfer-serve -j 8 > C:\Users\Morawake\ninfer-4090\build-v120.log 2>&1
exit /b %ERRORLEVEL%