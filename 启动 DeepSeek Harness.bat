@echo off
rem Wrapper only: every step lives in dsh-launcher.ps1 in this same folder.
rem Kept ASCII-only on purpose so no cmd code page can corrupt it.
if not exist "%~dp0dsh-launcher.ps1" (
  echo [DeepSeek Harness] dsh-launcher.ps1 is missing next to this file.
  echo                     Keep the two files together, then run this again.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dsh-launcher.ps1"
