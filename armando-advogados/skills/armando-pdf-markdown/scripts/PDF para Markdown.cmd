@echo off
chcp 65001 >nul
title PDF para Markdown
echo.
echo   PDF  --^>  Markdown
echo   ------------------
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pdf2md.ps1" %* -Pausar
