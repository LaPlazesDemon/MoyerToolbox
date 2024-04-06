@echo off
CLS
echo:
echo Cleaning up S:/ Drive
echo:

forfiles /S /P S:\Store\Database\Oracle\fast_recovery_area\RIS\ /M *.ARC /c "cmd /c del @file" /D -1
forfiles /S /P S:\Store\Database\Oracle\fast_recovery_area\RIS\ /M *.BKP /c "cmd /c del @file" /D -1
forfiles /S /P S:\Store\Database\Oracle\fast_recovery_area\RIS\ /M *.DBF /c "cmd /c del @file" /D -1

echo:
echo:
echo:
echo Drive Cleanup Complete
echo: