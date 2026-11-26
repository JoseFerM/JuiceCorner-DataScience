# =========================================================================
# JUICE CORNER BD - CARGADOR UNIVERSAL AUTOMATIZADO (POWERSHELL)
# Compatible con: SQL Server 2014, 2016, 2017, 2019, 2022, 2025
# =========================================================================
# Resuelve de forma definitiva:
#  - Comas dentro de comillas (direcciones de delivery y descripciones).
#  - Conversiones automáticas de tipos de datos (.NET SqlBulkCopy).
#  - Formato decimal internacional y booleanos True/False -> 1/0.
#  - Cero dependencias de versión de T-SQL o asistentes manuales.
# =========================================================================

[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.Data
Add-Type -AssemblyName Microsoft.VisualBasic

param (
    [string]$ServerInstance = "",
    [string]$Database = "JuiceCorner_OLTP",
    [string]$DatasetFolder = ""
)

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "CARGADOR MASIVO: JUICE CORNER OLTP (SQL SERVER 2014+)" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

# 1. DETECTAR RUTA DE ARCHIVOS CSV (100% PORTABLE CON RUTA RELATIVA)
$candidateFolders = @(
    $DatasetFolder,
    $PSScriptRoot,
    (Join-Path $PSScriptRoot "dataset"),
    "C:\Users\T001-DOC\Documents\Adobe\dataset\",
    "C:\Users\T001-DOC\Documents\Adobe\",
    "C:\Users\Agents\Documents\3.1proyecto\dataset\"
)

$foundFolder = $null
foreach ($f in $candidateFolders) {
    if (![string]::IsNullOrWhiteSpace($f) -and (Test-Path (Join-Path $f "categories.csv"))) {
        $foundFolder = $f
        break
    }
}

if (-not $foundFolder) {
    Write-Host "No se encontraron los archivos CSV en las rutas por defecto." -ForegroundColor Yellow
    $foundFolder = Read-Host "Ingresa la ruta completa de tu carpeta con los CSV (ej: C:\Users\T001-DOC\Documents\Adobe\)"
}

Write-Host "[OK] Carpeta de datos: $foundFolder" -ForegroundColor Green

# 2. CONECTAR AL SERVIDOR SQL
$candidateServers = @($ServerInstance, ".", "localhost", ".\SQLEXPRESS", "(localdb)\MSSQLLocalDB")
$conn = $null

foreach ($srv in $candidateServers) {
    if ([string]::IsNullOrWhiteSpace($srv)) { continue }
    try {
        $testConnStr = "Server=$srv;Database=$Database;Integrated Security=True;Connection Timeout=3;"
        $testConn = New-Object System.Data.SqlClient.SqlConnection($testConnStr)
        $testConn.Open()
        $conn = $testConn
        $ServerInstance = $srv
        Write-Host "[OK] Conectado exitosamente al servidor: $ServerInstance" -ForegroundColor Green
        break
    } catch {
        # Probar siguiente candidato
    }
}

if (-not $conn) {
    Write-Host "No se pudo conectar automáticamente." -ForegroundColor Yellow
    $ServerInstance = Read-Host "Escribe el nombre exacto de tu servidor SQL (ej: . o localhost o TU-PC\SQLEXPRESS)"
    $connStr = "Server=$ServerInstance;Database=$Database;Integrated Security=True;"
    try {
        $conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
        $conn.Open()
        Write-Host "[OK] Conectado exitosamente a $ServerInstance" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] No se pudo conectar: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Presiona cualquier tecla para salir..."
        [void][System.Console]::ReadKey()
        exit 1
    }
}

# 3. PREPARAR BASE DE DATOS (DESACTIVAR FK Y LIMPIAR DATOS PREVIOS)
Write-Host "-> Desactivando comprobación de claves foráneas..." -ForegroundColor Yellow
$cmd = $conn.CreateCommand()
$cmd.CommandText = "EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';"
$cmd.ExecuteNonQuery() | Out-Null

$cleanTables = @('order_items', 'payments', 'deliveries', 'reviews', 'orders', 'product_promotions', 'product_ingredients', 'dining_tables', 'customer_addresses', 'products', 'categories', 'branches', 'delivery_zones', 'customers', 'coupons', 'promotions', 'ingredients')
foreach ($tbl in $cleanTables) {
    $cmd.CommandText = "DELETE FROM dbo.$tbl;"
    try { $cmd.ExecuteNonQuery() | Out-Null } catch {}
}
Write-Host "[OK] Tablas limpias y listas para recibir datos." -ForegroundColor Green
Write-Host ""

# 4. FUNCIÓN GENÉRICA CON ESQUEMA TIPADO DIRECTO DE SQL SERVER
function Import-FastCsv {
    param(
        [string]$CsvFile,
        [string]$TableName,
        [scriptblock]$MapRow,
        [int]$BatchSize = 50000
    )

    $fullPath = Join-Path $foundFolder $CsvFile
    if (-not (Test-Path $fullPath)) {
        Write-Host "[SALTAR] $CsvFile no encontrado." -ForegroundColor Yellow
        return
    }

    Write-Host "-> Cargando $CsvFile en $TableName..." -NoNewline

    # Obtener el esquema exacto de la tabla de SQL Server
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter("SELECT TOP 0 * FROM $TableName", $conn)
    $dt = New-Object System.Data.DataTable
    $dt.Locale = [System.Globalization.CultureInfo]::InvariantCulture
    $adapter.Fill($dt) | Out-Null

    $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($fullPath)
    $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
    $parser.SetDelimiters(",")
    $parser.HasFieldsEnclosedInQuotes = $true

    $header = $parser.ReadFields()
    $idx = @{}
    for ($i = 0; $i -lt $header.Length; $i++) {
        $idx[$header[$i].Trim()] = $i
    }

    $copy = New-Object System.Data.SqlClient.SqlBulkCopy($conn, [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity, $null)
    $copy.DestinationTableName = $TableName
    $copy.BatchSize = $BatchSize
    $copy.BulkCopyTimeout = 600

    foreach ($col in $dt.Columns) {
        $copy.ColumnMappings.Add($col.ColumnName, $col.ColumnName) | Out-Null
    }

    $count = 0
    while (-not $parser.EndOfData) {
        $f = $parser.ReadFields()
        $row = $dt.NewRow()
        & $MapRow $row $f $idx
        $dt.Rows.Add($row)
        $count++

        if ($dt.Rows.Count -ge $BatchSize) {
            $copy.WriteToServer($dt)
            $dt.Clear()
        }
    }

    if ($dt.Rows.Count -gt 0) {
        $copy.WriteToServer($dt)
        $dt.Clear()
    }

    $parser.Close()
    $copy.Close()
    Write-Host " [OK: $count filas]" -ForegroundColor Green
}

# Helpers para tipos seguros
function To-Int($val) { if ([string]::IsNullOrWhiteSpace($val)) { return [DBNull]::Value } else { return [int]$val } }
function To-Long($val) { if ([string]::IsNullOrWhiteSpace($val)) { return [DBNull]::Value } else { return [long]$val } }
function To-Dec($val) { if ([string]::IsNullOrWhiteSpace($val)) { return [DBNull]::Value } else { return [decimal]$val } }
function To-Bool($val) { if ($val -eq "True" -or $val -eq "1") { return $true } else { return $false } }
function To-Date($val) { if ([string]::IsNullOrWhiteSpace($val)) { return [DBNull]::Value } else { return [datetime]$val } }
function To-Str($val) { if ([string]::IsNullOrWhiteSpace($val)) { return [DBNull]::Value } else { return [string]$val } }

# Las fechas se cargan directamente del dataset original de Kaggle (11/01/2026 al 21/06/2026, 162 dias).
# No se aplica escalamiento temporal artificial.


# =========================================================================
# 5. CARGA SECUENCIAL DE LOS 16 ARCHIVOS
# =========================================================================

# 1. categories
Import-FastCsv "categories.csv" "dbo.categories" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["name"] = To-Str $f[$idx["name"]]
    $r["description"] = To-Str $f[$idx["description"]]
}

# 2. branches
Import-FastCsv "branches.csv" "dbo.branches" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["name"] = To-Str $f[$idx["name"]]
    $r["address"] = To-Str $f[$idx["address"]]
    $r["phone"] = To-Str $f[$idx["phone"]]
    $r["latitude"] = To-Dec $f[$idx["latitude"]]
    $r["longitude"] = To-Dec $f[$idx["longitude"]]
    $r["is_active"] = To-Bool $f[$idx["is_active"]]
}

# 3. products
Import-FastCsv "products.csv" "dbo.products" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["category_id"] = To-Int $f[$idx["category_id"]]
    $r["name"] = To-Str $f[$idx["name"]]
    $r["description"] = To-Str $f[$idx["description"]]
    $r["price"] = To-Dec $f[$idx["price"]]
    $r["discounted_price"] = To-Dec $f[$idx["discounted_price"]]
    $r["is_seasonal"] = To-Bool $f[$idx["is_seasonal"]]
    $r["is_available"] = To-Bool $f[$idx["is_available"]]
}

# 4. dining_tables
Import-FastCsv "dining_tables.csv" "dbo.dining_tables" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["branch_id"] = To-Int $f[$idx["branch_id"]]
    $r["table_number"] = To-Str $f[$idx["table_number"]]
    $r["capacity"] = To-Int $f[$idx["capacity"]]
    $r["is_available"] = To-Bool $f[$idx["is_active"]]
}

# 5. delivery_zones
Import-FastCsv "delivery_zones.csv" "dbo.delivery_zones" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["name"] = To-Str $f[$idx["name"]]
    $r["delivery_fee"] = To-Dec $f[$idx["delivery_fee"]]
    $r["min_order_amount"] = To-Dec $f[$idx["min_order_amount"]]
    $r["estimated_minutes"] = To-Int $f[$idx["estimated_minutes"]]
    $r["is_active"] = To-Bool $f[$idx["is_active"]]
}

# 6. customers (5.000 filas)
Import-FastCsv "customers.csv" "dbo.customers" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["name"] = To-Str $f[$idx["name"]]
    $r["phone"] = To-Str $f[$idx["phone"]]
    $r["email"] = To-Str $f[$idx["email"]]
    $r["password_hash"] = To-Str $f[$idx["password_hash"]]
    $r["phone_verified"] = To-Bool $f[$idx["phone_verified"]]
    $r["email_verified"] = To-Bool $f[$idx["email_verified"]]
    $r["referral_code"] = To-Str $f[$idx["referral_code"]]
    $r["referred_by"] = To-Int $f[$idx["referred_by"]]
    $r["loyalty_balance"] = To-Dec $f[$idx["loyalty_balance"]]
    $r["created_at"] = To-Date $f[$idx["created_at"]]
}

# 7. customer_addresses (6.627 filas)
Import-FastCsv "customer_addresses.csv" "dbo.customer_addresses" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["customer_id"] = To-Int $f[$idx["customer_id"]]
    $r["zone_id"] = To-Int $f[$idx["zone_id"]]
    $r["address_line"] = To-Str $f[$idx["address_line"]]
    $r["is_default"] = To-Bool $f[$idx["is_default"]]
}

# 8. coupons
Import-FastCsv "coupons.csv" "dbo.coupons" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["code"] = To-Str $f[$idx["code"]]
    $r["discount_type"] = To-Str $f[$idx["discount_type"]]
    $r["discount_value"] = To-Dec $f[$idx["discount_value"]]
    $r["is_active"] = To-Bool $f[$idx["is_active"]]
}

# 9. promotions
Import-FastCsv "promotions.csv" "dbo.promotions" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["name"] = To-Str $f[$idx["title"]]
    $r["discount_percentage"] = To-Dec $f[$idx["discount_value"]]
    $r["start_date"] = To-Date $f[$idx["start_date"]]
    $r["end_date"] = To-Date $f[$idx["end_date"]]
    $r["is_active"] = To-Bool $f[$idx["is_active"]]
}

# 10. product_promotions
Import-FastCsv "product_promotions.csv" "dbo.product_promotions" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["product_id"] = To-Int $f[$idx["product_id"]]
    $r["promotion_id"] = To-Int $f[$idx["promotion_id"]]
}

# 11. orders (1.000.000 filas)
Import-FastCsv "orders.csv" "dbo.orders" {
    param($r, $f, $idx)
    $r["id"] = To-Long $f[$idx["id"]]
    $r["order_number"] = To-Str $f[$idx["order_number"]]
    $r["customer_id"] = To-Int $f[$idx["customer_id"]]
    $r["branch_id"] = To-Int $f[$idx["branch_id"]]
    $r["address_id"] = To-Int $f[$idx["address_id"]]
    $r["table_id"] = To-Int $f[$idx["table_id"]]
    $r["coupon_id"] = To-Int $f[$idx["coupon_id"]]
    $r["order_type"] = To-Str $f[$idx["order_type"]]
    $r["status"] = To-Str $f[$idx["status"]]
    $r["subtotal"] = To-Dec $f[$idx["subtotal"]]
    $r["discount_amount"] = To-Dec $f[$idx["discount_amount"]]
    $r["coupon_discount"] = To-Dec $f[$idx["coupon_discount"]]
    $r["delivery_fee"] = To-Dec $f[$idx["delivery_fee"]]
    $r["tax"] = To-Dec $f[$idx["tax"]]
    $r["total_amount"] = To-Dec $f[$idx["total_amount"]]
    $r["placed_at"] = To-Date $f[$idx["placed_at"]]
    $r["completed_at"] = To-Date $f[$idx["completed_at"]]
}

# 12. order_items (2.500.000 filas)
Import-FastCsv "order_items.csv" "dbo.order_items" {
    param($r, $f, $idx)
    $r["id"] = To-Long $f[$idx["id"]]
    $r["order_id"] = To-Long $f[$idx["order_id"]]
    $r["product_id"] = To-Int $f[$idx["product_id"]]
    $r["quantity"] = To-Int $f[$idx["quantity"]]
    $r["unit_price"] = To-Dec $f[$idx["unit_price"]]
    $r["discount"] = To-Dec $f[$idx["discount"]]
    $r["subtotal"] = To-Dec $f[$idx["subtotal"]]
}

# 13. payments (1.000.000 filas)
Import-FastCsv "payments.csv" "dbo.payments" {
    param($r, $f, $idx)
    $r["id"] = To-Long $f[$idx["id"]]
    $r["order_id"] = To-Long $f[$idx["order_id"]]
    $r["method"] = To-Str $f[$idx["method"]]
    $r["amount"] = To-Dec $f[$idx["amount"]]
    $r["status"] = To-Str $f[$idx["status"]]
    $r["paid_at"] = To-Date $f[$idx["paid_at"]]
}

# 14. deliveries (700.000 filas)
Import-FastCsv "deliveries.csv" "dbo.deliveries" {
    param($r, $f, $idx)
    $r["id"] = To-Long $f[$idx["id"]]
    $r["order_id"] = To-Long $f[$idx["order_id"]]
    $r["delivery_person_id"] = To-Int $f[$idx["delivery_person_id"]]
    $r["assigned_at"] = To-Date $f[$idx["assigned_at"]]
    $r["delivered_at"] = To-Date $f[$idx["delivered_at"]]
    $r["status"] = To-Str $f[$idx["status"]]
}

# 15. reviews (600.000 filas)
Import-FastCsv "reviews.csv" "dbo.reviews" {
    param($r, $f, $idx)
    $r["id"] = To-Long $f[$idx["id"]]
    $r["order_id"] = To-Long $f[$idx["order_id"]]
    $r["product_id"] = To-Int $f[$idx["product_id"]]
    $r["customer_id"] = To-Int $f[$idx["customer_id"]]
    $r["rating"] = [byte]$f[$idx["rating"]]
    $r["comment"] = To-Str $f[$idx["comment"]]
    $r["is_approved"] = To-Bool $f[$idx["is_approved"]]
    $r["created_at"] = To-Date $f[$idx["created_at"]]
}

# 16. ingredients & product_ingredients
Import-FastCsv "ingredients.csv" "dbo.ingredients" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["name"] = To-Str $f[$idx["name"]]
    $r["unit"] = To-Str $f[$idx["unit"]]
    $r["cost_per_unit"] = To-Dec $f[$idx["cost_per_unit"]]
    $r["current_stock"] = To-Dec $f[$idx["current_stock"]]
    $r["reorder_level"] = To-Dec $f[$idx["reorder_level"]]
    $r["is_active"] = To-Bool $f[$idx["is_active"]]
}

Import-FastCsv "product_ingredients.csv" "dbo.product_ingredients" {
    param($r, $f, $idx)
    $r["id"] = To-Int $f[$idx["id"]]
    $r["product_id"] = To-Int $f[$idx["product_id"]]
    $r["ingredient_id"] = To-Int $f[$idx["ingredient_id"]]
    $r["quantity"] = To-Dec $f[$idx["quantity"]]
    $r["unit"] = To-Str $f[$idx["unit"]]
}

# 6. REACTIVAR CLAVES FORÁNEAS
Write-Host ""
Write-Host "-> Reactivando y validando claves foráneas..." -ForegroundColor Yellow
$cmd.CommandText = "EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';"
$cmd.ExecuteNonQuery() | Out-Null
Write-Host "[OK] Claves foráneas reactivadas y validadas." -ForegroundColor Green

Write-Host ""
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "CARGA COMPLETA FINALIZADA CON ÉXITO EN JUICECORNER_OLTP" -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Cyan

$conn.Close()
Write-Host ""
Write-Host "Presiona cualquier tecla para cerrar esta ventana..."
[void][System.Console]::ReadKey()
