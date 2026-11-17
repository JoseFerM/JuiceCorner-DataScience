# ===============================================================================
# JUICE CORNER BD - SCRIPT POWERSHELL DE EJECUCIÓN Y GESTIÓN SQL
# Servidor: Microsoft SQL Server (localdb)\MSSQLLocalDB
# ===============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Server = "(localdb)\MSSQLLocalDB"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Ensure-LocalDBStarted {
    Write-Host "Verificando estado de SQL Server LocalDB ($Server)..." -ForegroundColor Cyan
    $status = sqllocaldb info MSSQLLocalDB
    if ($status -match "Detenido|Stopped") {
        Write-Host "Iniciando MSSQLLocalDB..." -ForegroundColor Yellow
        sqllocaldb start MSSQLLocalDB | Out-Null
    }
    Write-Host "SQL Server LocalDB está activo y listo." -ForegroundColor Green
}

function Run-SqlScript($fileName) {
    Ensure-LocalDBStarted
    $filePath = Join-Path $ScriptDir $fileName
    if (-not (Test-Path $filePath)) {
        Write-Host "Error: No se encontró el archivo $filePath" -ForegroundColor Red
        return
    }
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "Ejecutando: $fileName" -ForegroundColor White
    Write-Host "========================================================`n" -ForegroundColor Cyan
    sqlcmd -S $Server -i $filePath
    Write-Host "`nEjecución finalizada." -ForegroundColor Green
}

function Show-Status {
    Ensure-LocalDBStarted
    Write-Host "`n--- Base de Datos: JuiceCorner_OLTP ---" -ForegroundColor Yellow
    sqlcmd -S $Server -d JuiceCorner_OLTP -Q "SELECT TABLE_SCHEMA + '.' + TABLE_NAME AS Tabla FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;"
    
    Write-Host "`n--- Base de Datos: JuiceCorner_DW (Data Warehouse) ---" -ForegroundColor Magenta
    sqlcmd -S $Server -d JuiceCorner_DW -Q "SELECT TABLE_SCHEMA + '.' + TABLE_NAME AS Tabla FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_SCHEMA DESC, TABLE_NAME;"
}

function Run-CustomQuery {
    Ensure-LocalDBStarted
    $db = Read-Host "`nIngresa la base de datos (1 = JuiceCorner_OLTP, 2 = JuiceCorner_DW)"
    $dbName = if ($db -eq "2") { "JuiceCorner_DW" } else { "JuiceCorner_OLTP" }
    $query = Read-Host "Ingresa tu consulta SQL (Ej: SELECT * FROM DIM_TIEMPO)"
    if ([string]::IsNullOrWhiteSpace($query)) { return }
    Write-Host "`nResultado en $dbName:" -ForegroundColor Cyan
    sqlcmd -S $Server -d $dbName -Q $query
}

do {
    Clear-Host
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "                JUICE CORNER BD - EJECUTOR Y VISUALIZADOR SQL" -ForegroundColor Yellow
    Write-Host "               Servidor: Microsoft SQL Server $Server" -ForegroundColor Gray
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "  [1] Ejecutar JuiceCorner_OLTP.sql (Base Transaccional OLTP)"
    Write-Host "  [2] Ejecutar JuiceCorner_DW.sql   (Data Warehouse Estrella DW)"
    Write-Host "  [3] Ejecutar Ambos Scripts en secuencia"
    Write-Host "  [4] Ver estado (Tablas en ambas bases de datos)"
    Write-Host "  [5] Ejecutar una consulta SQL rápida en consola"
    Write-Host "  [6] Abrir VS Code en este proyecto"
    Write-Host "  [7] Abrir Visualizador Web Interactivo (ERD / Diccionario)"
    Write-Host "  [0] Salir"
    Write-Host "===============================================================================" -ForegroundColor Cyan
    $op = Read-Host "Selecciona una opción (0-7)"

    switch ($op) {
        "1" { Run-SqlScript "JuiceCorner_OLTP.sql"; Read-Host "`nPresiona Enter para continuar..." }
        "2" { Run-SqlScript "JuiceCorner_DW.sql";   Read-Host "`nPresiona Enter para continuar..." }
        "3" { 
            Run-SqlScript "JuiceCorner_OLTP.sql"
            Run-SqlScript "JuiceCorner_DW.sql"
            Read-Host "`nPresiona Enter para continuar..." 
        }
        "4" { Show-Status; Read-Host "`nPresiona Enter para continuar..." }
        "5" { Run-CustomQuery; Read-Host "`nPresiona Enter para continuar..." }
        "6" { code $ScriptDir }
        "7" { 
            $webPath = Join-Path $ScriptDir "visualizador_sql.html"
            if (Test-Path $webPath) { Start-Process $webPath } else { Write-Host "Archivo no encontrado" -ForegroundColor Red }
        }
    }
} while ($op -ne "0")
