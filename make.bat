@echo off
REM ==========================================================
REM        MASM PROJECT BUILD SCRIPT (MODULAR VERSION)
REM ==========================================================

setlocal

REM --- DIRECTORY CONFIG ---
set SRC=src
set OBJ=obj
set BIN=bin
set INCLUDE=include
set LIB=lib
set TOOLS=tools

REM --- ENTRY FILE ---
set ENTRY=%1
if "%ENTRY%"=="" set ENTRY=main

echo ===========================================
echo Building Assembly Project
echo Entry file: %ENTRY%.asm
echo ===========================================

REM --- CREATE OUTPUT DIRECTORIES ---
if not exist "%OBJ%" mkdir "%OBJ%"
if not exist "%BIN%" mkdir "%BIN%"

echo.
echo ===== Step 1: Assembling all .asm files =====

for %%f in (%SRC%\*.asm) do (
    echo Assembling %%~nxf ...
    "%TOOLS%\ml.exe" /c /coff /Zi ^
        /Fo"%OBJ%\%%~nf.obj" ^
        /Fl"%OBJ%\%%~nf.lst" ^
        /I "%INCLUDE%" "%%f"
    if errorlevel 1 goto fail
)

echo.
echo ===== Step 2: Linking all modules =====

"%TOOLS%\link.exe" /INCREMENTAL:no /debug /subsystem:console ^
    /entry:start ^
    /out:"%BIN%\%ENTRY%.exe" ^
    "%OBJ%\main.obj" ^
    "%LIB%\kernel32.lib" ^
    "%LIB%\user32.lib" ^
    "%LIB%\irvine32.lib"

if errorlevel 1 goto fail

echo.
echo Build successful!
echo Output files:
dir "%BIN%\%ENTRY%.*"

pause
endlocal
goto :eof

:fail
echo.
echo BUILD FAILED — SEE ERROR MESSAGES ABOVE
pause
endlocal
