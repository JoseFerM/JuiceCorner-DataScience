@echo off
TITLE Cargador Juice Corner OLTP - SQL Server 2014+
COLOR 0B
echo =========================================================================
echo    INICIANDO CARGADOR AUTOMATIZADO PARA JUICE CORNER BD (SQL 2014)
echo =========================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Cargar_Datos_OLTP.ps1"

pause
