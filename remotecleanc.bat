@echo off

echo Clearing Temp Files

forfiles /P C:\WINDOWS\system32\LogFiles\W3SVC1\ /M ex*.log /c "cmd /c del @file"
forfiles /P C:\Progra~1\Store\Temp\ /M *.*.*.* /c "cmd /c del @file" /D -7
forfiles /P C:\Progra~1\Store\Temp\ /M *.log /c "cmd /c del @file" /D -7
forfiles /P C:\Progra~1\Store\Temp\ /M *.gz /c "cmd /c del @file" /D -7
forfiles /P C:\Progra~1\Store\Temp\ /M csh* /c "cmd /c del @file" /D -7
forfiles /P C:\Progra~1\Store\Temp\ /M damagedmodetail* /c "cmd /c del @file" /D -7
forfiles /P C:\Progra~1\Store\Temp\ /M plogfile* /c "cmd /c del @file" /D -7
forfiles /P C:\Progra~1\Store\Log /M mini* /c "cmd /c del @file" /D -7 
forfiles /S /P C:\ACS_SUPPORT_LOGS\ /M *.tx* /c "cmd /c del @file" /D -14
forfiles /S /P C:\Document~1\ /M drwtsn32.log /c "cmd /c del @file"

echo Deleting Specified Files

cd C:\ACS_SUPPORT_LOGS\SAFE
del *old*

cd C:\ACS_SUPPORT_LOGS\EDH
del *old*

cd C:\ACS_SUPPORT_LOGS\FUEL
del *old*

cd C:\ACS_SUPPORT_LOGS\MW
del *old*

cd C:\ACS_SUPPORT_LOGS\NW
del *old*

cd C:\ACS_SUPPORT_LOGS\POS
del *old*

cd C:\Progra~1\Store\Log
del *.old
del bo3gl*.log
del ntcron*.log
del mini*.dmp

cd C:\Progra~1\Store\Log\System\StoreServices
del *.log

cd C:\Progra~1\Store\Log\System\Scss
del *.log

echo Drive Cleanup Has Completed

pause
