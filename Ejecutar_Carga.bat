@echo off
chcp 65001 > nul
TITLE Cargador Juice Corner OLTP - SQL Server 2014+
COLOR 0B
echo =========================================================================
echo    INICIANDO CARGADOR AUTOMATIZADO PARA JUICE CORNER BD (SQL 2014+)
echo =========================================================================
echo.

echo [1/3] Asegurando que la instancia LocalDB este iniciada...
sqllocaldb start MSSQLLocalDB > nul 2>&1

set PS_SCRIPT=
if exist "%~dp0Cargar_Datos_OLTP.ps1" (
    set PS_SCRIPT=%~dp0Cargar_Datos_OLTP.ps1
) else if exist "%~dp0dataset\Cargar_Datos_OLTP.ps1" (
    set PS_SCRIPT=%~dp0dataset\Cargar_Datos_OLTP.ps1
) else if exist "%~dp0..\Cargar_Datos_OLTP.ps1" (
    set PS_SCRIPT=%~dp0..\Cargar_Datos_OLTP.ps1
)

if "%PS_SCRIPT%"=="" (
    echo [ERROR] No se encontro el archivo Cargar_Datos_OLTP.ps1.
    echo Asegurate de que este en esta carpeta o en la carpeta dataset.
    pause
    exit /b 1
)

echo [2/3] Script detectado en: %PS_SCRIPT%
echo [3/3] Ejecutando carga masiva OLTP...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

echo.
echo =========================================================================
echo Proceso finalizado.
echo =========================================================================
pause
