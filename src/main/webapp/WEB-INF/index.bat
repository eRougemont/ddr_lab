@echo off 
setlocal
SET DIR=%~dp0
java -cp "%DIR%/lib/*" alix.cli.Load %*
REM TOUCH ?
@COPY /B %DIR%web.xml +,,

