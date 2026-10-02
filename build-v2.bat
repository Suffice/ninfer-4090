@echo off
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
cmake --build build-ninja --target ninfer_artifact_materialization_test -j 8
exit /b %ERRORLEVEL%
