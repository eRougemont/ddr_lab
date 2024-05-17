@echo off 
setlocal
SET DIR=%~dp0../target/ddr_lab/WEB-INF/
java -cp "%DIR%lib/*" com.github.oeuvres.alix.cli.Load %*
REM TOUCH ?
COPY /B %DIR%web.xml +,,

