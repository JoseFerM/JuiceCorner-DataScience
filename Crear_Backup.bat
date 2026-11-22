@echo off
chcp 65001 > nul
title JuiceCorner - Generador de Backup .BAK
color 0A

echo ===============================================================================
echo            JUICE CORNER BD - GENERADOR DE COPIA DE SEGURIDAD (.BAK)
echo           Servidor: Microsoft SQL Server (localdb)\MSSQLLocalDB
echo ===============================================================================
echo.

set SERVER_NAME=(localdb)\MSSQLLocalDB
set OUTPUT_PATH=%~dp0JuiceCorner_OLTP.bak

echo [1/3] Verificando instancia LocalDB...
sqllocaldb start MSSQLLocalDB > nul 2>&1

echo [2/3] Generando backup completo de JuiceCorner_OLTP con todos los datos...
echo Destino: %OUTPUT_PATH%
echo.

sqlcmd -S "%SERVER_NAME%" -Q "BACKUP DATABASE JuiceCorner_OLTP TO DISK = N'%OUTPUT_PATH%' WITH FORMAT, INIT, STATS = 10;"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [3/3] Validando integridad del archivo .bak...
    sqlcmd -S "%SERVER_NAME%" -Q "RESTORE VERIFYONLY FROM DISK = N'%OUTPUT_PATH%';"
    echo.
    echo ===============================================================================
    echo [EXITO] Archivo .bak generado y validado con exito en:
    echo         %OUTPUT_PATH%
    echo ===============================================================================
) else (
    echo.
    echo [ERROR] Ocurrio un error al generar el backup. Revisa que SQL Server este iniciado.
)

echo.
pause
