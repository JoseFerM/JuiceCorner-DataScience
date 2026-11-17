@echo off
chcp 65001 > nul
title Juice Corner BD - Gestor de Ejecución SQL
color 0B

:MENU
cls
echo ===============================================================================
echo                JUICE CORNER BD - EJECUTOR Y VISUALIZADOR SQL
echo               Servidor: Microsoft SQL Server (localdb)\MSSQLLocalDB
echo ===============================================================================
echo.
echo  [1] Iniciar servicio LocalDB y verificar conexión
echo  [2] Ejecutar JuiceCorner_OLTP.sql (Crear / Reinicializar Base Transaccional)
echo  [3] Ejecutar JuiceCorner_DW.sql   (Crear / Reinicializar Data Warehouse Estrella)
echo  [4] Ejecutar AMBOS scripts (OLTP + DW en orden)
echo  [5] Ver estado actual (Tablas y conteo de filas en ambas bases de datos)
echo  [6] Abrir VS Code en este proyecto (con extensiones SQL preconfiguradas)
echo  [7] Abrir Visualizador Web Interactivo (Studio ERD y Diccionario de Datos)
echo  [0] Salir
echo.
echo ===============================================================================
set /p OPCION="Selecciona una opción (0-7): "

if "%OPCION%"=="1" goto TEST_CONEXION
if "%OPCION%"=="2" goto RUN_OLTP
if "%OPCION%"=="3" goto RUN_DW
if "%OPCION%"=="4" goto RUN_AMBOS
if "%OPCION%"=="5" goto STATUS
if "%OPCION%"=="6" goto OPEN_VSCODE
if "%OPCION%"=="7" goto OPEN_WEB
if "%OPCION%"=="0" goto FIN

echo Opción inválida.
pause
goto MENU

:TEST_CONEXION
cls
echo [1/2] Iniciando instancia LocalDB MSSQLLocalDB...
sqllocaldb start MSSQLLocalDB
echo.
echo [2/2] Probando conexión con sqlcmd...
sqlcmd -S "(localdb)\MSSQLLocalDB" -Q "SELECT @@VERSION as [Versión de SQL Server];"
echo.
pause
goto MENU

:RUN_OLTP
cls
echo ===============================================================================
echo Ejecutando JuiceCorner_OLTP.sql...
echo ===============================================================================
sqllocaldb start MSSQLLocalDB > nul 2>&1
sqlcmd -S "(localdb)\MSSQLLocalDB" -i "%~dp0JuiceCorner_OLTP.sql"
echo.
echo Proceso finalizado.
pause
goto MENU

:RUN_DW
cls
echo ===============================================================================
echo Ejecutando JuiceCorner_DW.sql...
echo ===============================================================================
sqllocaldb start MSSQLLocalDB > nul 2>&1
sqlcmd -S "(localdb)\MSSQLLocalDB" -i "%~dp0JuiceCorner_DW.sql"
echo.
echo Proceso finalizado.
pause
goto MENU

:RUN_AMBOS
cls
echo ===============================================================================
echo Paso 1 de 2: Ejecutando JuiceCorner_OLTP.sql...
echo ===============================================================================
sqllocaldb start MSSQLLocalDB > nul 2>&1
sqlcmd -S "(localdb)\MSSQLLocalDB" -i "%~dp0JuiceCorner_OLTP.sql"
echo.
echo ===============================================================================
echo Paso 2 de 2: Ejecutando JuiceCorner_DW.sql...
echo ===============================================================================
sqlcmd -S "(localdb)\MSSQLLocalDB" -i "%~dp0JuiceCorner_DW.sql"
echo.
echo ¡Ambos scripts se ejecutaron exitosamente!
pause
goto MENU

:STATUS
cls
echo ===============================================================================
echo TABLAS EN JuiceCorner_OLTP:
echo ===============================================================================
sqlcmd -S "(localdb)\MSSQLLocalDB" -d JuiceCorner_OLTP -Q "SELECT TABLE_SCHEMA + '.' + TABLE_NAME AS Tabla FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;"
echo.
echo ===============================================================================
echo TABLAS EN JuiceCorner_DW (Esquema Estrella):
echo ===============================================================================
sqlcmd -S "(localdb)\MSSQLLocalDB" -d JuiceCorner_DW -Q "SELECT TABLE_SCHEMA + '.' + TABLE_NAME AS Tabla FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_SCHEMA DESC, TABLE_NAME;"
echo.
pause
goto MENU

:OPEN_VSCODE
echo Abriendo VS Code con el proyecto...
start "" code "%~dp0"
goto MENU

:OPEN_WEB
echo Abriendo Visualizador Interactivo en el navegador...
if exist "%~dp0visualizador_sql.html" (
    start "" "%~dp0visualizador_sql.html"
) else (
    echo El archivo visualizador_sql.html aún no está disponible.
)
pause
goto MENU

:FIN
exit /b 0
