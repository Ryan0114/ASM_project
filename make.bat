@echo off
REM ==========================================================
REM   MASM Build Script - Assembles and links 32-bit program
REM   Compatible with WinDbg
REM   Author: Huang
REM ==========================================================

setlocal

REM --- CONFIGURABLE SETTINGS ---
set SRC=src
set OBJ=obj
set BIN=bin
set INCLUDE=include
set LIB=lib
set TOOLS=tools

set ASM_FILE=%1
if "%ASM_FILE%"=="" set ASM_FILE=main

REM --- CREATE OUTPUT DIRECTORIES IF NOT EXIST ---
if not exist "%OBJ%" mkdir "%OBJ%"
if not exist "%BIN%" mkdir "%BIN%"

REM --- ASSEMBLE ---
echo Assembling %ASM_FILE%.asm ...
"%TOOLS%\ml.exe" /c /coff /Zi /Fl"%OBJ%\%ASM_FILE%.lst" /Fo"%OBJ%\%ASM_FILE%.obj" /I "%INCLUDE%" "%SRC%\%ASM_FILE%.asm"
if errorlevel 1 goto terminate

REM --- LINK ---
echo Linking %ASM_FILE%.exe ...
"%TOOLS%\link.exe" /INCREMENTAL:no /debug /subsystem:console /entry:start ^
/out:"%BIN%\%ASM_FILE%.exe" "%OBJ%\%ASM_FILE%.obj" ^
"%LIB%\irvine32.lib" "%LIB%\kernel32.lib" "%LIB%\user32.lib"
if errorlevel 1 goto terminate

REM --- DISPLAY OUTPUT ---
echo Build complete.
dir "%BIN%\%ASM_FILE%.*"

:terminate
echo.
pause
endlocal
