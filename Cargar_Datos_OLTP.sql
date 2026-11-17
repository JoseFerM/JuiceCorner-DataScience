-- =========================================================================
-- JUICE CORNER BD - SCRIPT DE CARGA MASIVA AUTOMATIZADA (OLTP)
-- Motor: Microsoft SQL Server (Compatible con 2014, 2016, 2017, 2019, 2022, 2025)
--
-- Propósito:
--   Carga los 16 archivos CSV del dataset de Kaggle directamente a las
--   tablas de JuiceCorner_OLTP usando BULK INSERT de alto rendimiento.
--   - Compatible con sintaxis de SQL Server 2014 (sin DROP TABLE IF EXISTS).
--   - Detección dinámica de versión para opciones de importación.
--   - Desactiva y reactiva las restricciones de claves foráneas automáticamente.
-- =========================================================================

USE JuiceCorner_OLTP;
GO

SET NOCOUNT ON;
GO

-- =========================================================================
-- 1. CONFIGURACIÓN DE RUTA DEL DATASET
-- Ajusta esta ruta si tus archivos CSV están en otra carpeta.
-- =========================================================================
DECLARE @RutaDataset VARCHAR(500) = 'C:\Users\Agents\Documents\3.1proyecto\dataset\';

-- Si la ruta no termina en barra diagonal inversa, se la agregamos
IF RIGHT(@RutaDataset, 1) <> '\' SET @RutaDataset = @RutaDataset + '\';

-- Detección de versión del motor (Compatible desde SQL Server 2008 hasta 2025)
DECLARE @MajorVersion INT = CAST(PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)), 4) AS INT);
DECLARE @BulkOptions NVARCHAR(300);

-- Si es SQL Server 2017+ (v14+) usa el motor CSV moderno con comillas; si es 2014 (v12) usa delimitadores clásicos
IF @MajorVersion >= 14
    SET @BulkOptions = ' WITH (FORMAT = ''CSV'', FIRSTROW = 2, FIELDQUOTE = ''"'');';
ELSE
    SET @BulkOptions = ' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'');';

DECLARE @sql NVARCHAR(MAX);
DECLARE @HoraInicio DATETIME2 = SYSDATETIME();

PRINT '=========================================================================';
PRINT 'INICIANDO CARGA MASIVA AUTOMATIZADA EN JuiceCorner_OLTP';
PRINT 'Ruta de datos: ' + @RutaDataset;
PRINT 'Versión detectada de SQL Server: ' + CAST(@MajorVersion AS VARCHAR(10));
PRINT 'Hora de inicio: ' + CONVERT(VARCHAR(30), @HoraInicio, 120);
PRINT '=========================================================================';
PRINT '';

-- 2. DESACTIVAR TEMPORALMENTE TODAS LAS CLAVES FORÁNEAS
PRINT '-> Desactivando comprobación de claves foráneas...';
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
PRINT '   Comprobaciones desactivadas correctamente.';
PRINT '';


-- =========================================================================
-- 3. CARGA DE TABLAS MAESTRAS Y CATÁLOGOS
-- =========================================================================

-- 1. CATEGORIES
PRINT '1/16 Cargando categories.csv...';
IF OBJECT_ID('tempdb..#stg_categories') IS NOT NULL DROP TABLE #stg_categories;
CREATE TABLE #stg_categories (
    id INT, name VARCHAR(100), description VARCHAR(500),
    display_order INT, is_active VARCHAR(10), created_at VARCHAR(50), updated_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_categories FROM ''' + @RutaDataset + 'categories.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.categories ON;
INSERT INTO dbo.categories (id, name, description)
SELECT id, name, description FROM #stg_categories;
SET IDENTITY_INSERT dbo.categories OFF;
IF OBJECT_ID('tempdb..#stg_categories') IS NOT NULL DROP TABLE #stg_categories;


-- 2. BRANCHES
PRINT '2/16 Cargando branches.csv...';
IF OBJECT_ID('tempdb..#stg_branches') IS NOT NULL DROP TABLE #stg_branches;
CREATE TABLE #stg_branches (
    id INT, name VARCHAR(120), address VARCHAR(255), phone VARCHAR(30),
    latitude DECIMAL(10,7), longitude DECIMAL(10,7), is_active VARCHAR(10),
    created_at VARCHAR(50), updated_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_branches FROM ''' + @RutaDataset + 'branches.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.branches ON;
INSERT INTO dbo.branches (id, name, address, phone, latitude, longitude, is_active)
SELECT id, name, address, phone, latitude, longitude,
       CASE WHEN is_active = 'True' THEN 1 ELSE 0 END
FROM #stg_branches;
SET IDENTITY_INSERT dbo.branches OFF;
IF OBJECT_ID('tempdb..#stg_branches') IS NOT NULL DROP TABLE #stg_branches;


-- 3. PRODUCTS
PRINT '3/16 Cargando products.csv...';
IF OBJECT_ID('tempdb..#stg_products') IS NOT NULL DROP TABLE #stg_products;
CREATE TABLE #stg_products (
    id INT, category_id INT, name VARCHAR(150), description VARCHAR(500),
    price DECIMAL(12,2), discounted_price DECIMAL(12,2), is_seasonal VARCHAR(10),
    is_available VARCHAR(10), created_at VARCHAR(50), updated_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_products FROM ''' + @RutaDataset + 'products.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.products ON;
INSERT INTO dbo.products (id, category_id, name, description, price, discounted_price, is_seasonal, is_available)
SELECT id, category_id, name, description, price, discounted_price,
       CASE WHEN is_seasonal = 'True' THEN 1 ELSE 0 END,
       CASE WHEN is_available = 'True' THEN 1 ELSE 0 END
FROM #stg_products;
SET IDENTITY_INSERT dbo.products OFF;
IF OBJECT_ID('tempdb..#stg_products') IS NOT NULL DROP TABLE #stg_products;


-- 4. DINING_TABLES
PRINT '4/16 Cargando dining_tables.csv...';
IF OBJECT_ID('tempdb..#stg_dining_tables') IS NOT NULL DROP TABLE #stg_dining_tables;
CREATE TABLE #stg_dining_tables (
    id INT, branch_id INT, table_number VARCHAR(20), capacity VARCHAR(50),
    status VARCHAR(30), qr_code VARCHAR(100), is_active VARCHAR(10)
);
SET @sql = 'BULK INSERT #stg_dining_tables FROM ''' + @RutaDataset + 'dining_tables.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.dining_tables ON;
INSERT INTO dbo.dining_tables (id, branch_id, table_number, capacity, is_available)
SELECT id, branch_id, table_number, TRY_CAST(NULLIF(capacity, '') AS INT),
       CASE WHEN is_active = 'True' THEN 1 ELSE 0 END
FROM #stg_dining_tables;
SET IDENTITY_INSERT dbo.dining_tables OFF;
IF OBJECT_ID('tempdb..#stg_dining_tables') IS NOT NULL DROP TABLE #stg_dining_tables;


-- 5. DELIVERY_ZONES
PRINT '5/16 Cargando delivery_zones.csv...';
IF OBJECT_ID('tempdb..#stg_delivery_zones') IS NOT NULL DROP TABLE #stg_delivery_zones;
CREATE TABLE #stg_delivery_zones (
    id INT, name VARCHAR(120), delivery_fee DECIMAL(12,2),
    min_order_amount DECIMAL(12,2), estimated_minutes INT, is_active VARCHAR(10)
);
SET @sql = 'BULK INSERT #stg_delivery_zones FROM ''' + @RutaDataset + 'delivery_zones.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.delivery_zones ON;
INSERT INTO dbo.delivery_zones (id, name, delivery_fee, min_order_amount, estimated_minutes, is_active)
SELECT id, name, delivery_fee, min_order_amount, estimated_minutes,
       CASE WHEN is_active = 'True' THEN 1 ELSE 0 END
FROM #stg_delivery_zones;
SET IDENTITY_INSERT dbo.delivery_zones OFF;
IF OBJECT_ID('tempdb..#stg_delivery_zones') IS NOT NULL DROP TABLE #stg_delivery_zones;


-- 6. CUSTOMERS
PRINT '6/16 Cargando customers.csv (5.000 filas)...';
IF OBJECT_ID('tempdb..#stg_customers') IS NOT NULL DROP TABLE #stg_customers;
CREATE TABLE #stg_customers (
    id INT, name VARCHAR(150), phone VARCHAR(30), email VARCHAR(150),
    password_hash VARCHAR(255), phone_verified VARCHAR(10), email_verified VARCHAR(10),
    loyalty_balance VARCHAR(50), referral_code VARCHAR(50), referred_by VARCHAR(50),
    created_at VARCHAR(50), updated_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_customers FROM ''' + @RutaDataset + 'customers.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.customers ON;
INSERT INTO dbo.customers (id, name, phone, email, password_hash, phone_verified, email_verified, referral_code, referred_by, loyalty_balance, created_at)
SELECT id, name, phone, email, password_hash,
       CASE WHEN phone_verified = 'True' THEN 1 ELSE 0 END,
       CASE WHEN email_verified = 'True' THEN 1 ELSE 0 END,
       NULLIF(referral_code, ''),
       TRY_CAST(NULLIF(referred_by, '') AS INT),
       ISNULL(TRY_CAST(NULLIF(loyalty_balance, '') AS DECIMAL(12,2)), 0),
       ISNULL(TRY_CAST(created_at AS DATETIME2(0)), SYSDATETIME())
FROM #stg_customers;
SET IDENTITY_INSERT dbo.customers OFF;
IF OBJECT_ID('tempdb..#stg_customers') IS NOT NULL DROP TABLE #stg_customers;


-- 7. CUSTOMER_ADDRESSES
PRINT '7/16 Cargando customer_addresses.csv (6.627 filas)...';
IF OBJECT_ID('tempdb..#stg_addresses') IS NOT NULL DROP TABLE #stg_addresses;
CREATE TABLE #stg_addresses (
    id INT, customer_id INT, zone_id INT, label VARCHAR(50),
    recipient_name VARCHAR(150), recipient_phone VARCHAR(50),
    address_line VARCHAR(300), area VARCHAR(100), city VARCHAR(100),
    postal_code VARCHAR(30), landmark VARCHAR(150), delivery_instructions VARCHAR(300),
    latitude VARCHAR(50), longitude VARCHAR(50), is_default VARCHAR(10), created_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_addresses FROM ''' + @RutaDataset + 'customer_addresses.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.customer_addresses ON;
INSERT INTO dbo.customer_addresses (id, customer_id, zone_id, address_line, is_default)
SELECT id, customer_id, zone_id, address_line,
       CASE WHEN is_default = 'True' THEN 1 ELSE 0 END
FROM #stg_addresses;
SET IDENTITY_INSERT dbo.customer_addresses OFF;
IF OBJECT_ID('tempdb..#stg_addresses') IS NOT NULL DROP TABLE #stg_addresses;


-- 8. COUPONS
PRINT '8/16 Cargando coupons.csv...';
IF OBJECT_ID('tempdb..#stg_coupons') IS NOT NULL DROP TABLE #stg_coupons;
CREATE TABLE #stg_coupons (
    id INT, code VARCHAR(50), title VARCHAR(150), description VARCHAR(500),
    discount_type VARCHAR(30), discount_value DECIMAL(12,2), min_order_amount VARCHAR(50),
    max_discount VARCHAR(50), usage_limit VARCHAR(50), per_customer_limit VARCHAR(50),
    used_count VARCHAR(50), start_date VARCHAR(50), end_date VARCHAR(50),
    is_active VARCHAR(10), created_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_coupons FROM ''' + @RutaDataset + 'coupons.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.coupons ON;
INSERT INTO dbo.coupons (id, code, discount_type, discount_value, is_active)
SELECT id, code, discount_type, discount_value,
       CASE WHEN is_active = 'True' THEN 1 ELSE 0 END
FROM #stg_coupons;
SET IDENTITY_INSERT dbo.coupons OFF;
IF OBJECT_ID('tempdb..#stg_coupons') IS NOT NULL DROP TABLE #stg_coupons;


-- 9. PROMOTIONS
PRINT '9/16 Cargando promotions.csv...';
IF OBJECT_ID('tempdb..#stg_promotions') IS NOT NULL DROP TABLE #stg_promotions;
CREATE TABLE #stg_promotions (
    id INT, title VARCHAR(150), description VARCHAR(500),
    discount_type VARCHAR(30), discount_value DECIMAL(5,2),
    start_date VARCHAR(50), end_date VARCHAR(50),
    is_active VARCHAR(10), created_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_promotions FROM ''' + @RutaDataset + 'promotions.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.promotions ON;
INSERT INTO dbo.promotions (id, name, discount_percentage, start_date, end_date, is_active)
SELECT id, title, discount_value,
       TRY_CAST(start_date AS DATE), TRY_CAST(end_date AS DATE),
       CASE WHEN is_active = 'True' THEN 1 ELSE 0 END
FROM #stg_promotions;
SET IDENTITY_INSERT dbo.promotions OFF;
IF OBJECT_ID('tempdb..#stg_promotions') IS NOT NULL DROP TABLE #stg_promotions;


-- 10. PRODUCT_PROMOTIONS
PRINT '10/16 Cargando product_promotions.csv...';
IF OBJECT_ID('tempdb..#stg_prod_prom') IS NOT NULL DROP TABLE #stg_prod_prom;
CREATE TABLE #stg_prod_prom (
    id INT, product_id INT, promotion_id INT
);
SET @sql = 'BULK INSERT #stg_prod_prom FROM ''' + @RutaDataset + 'product_promotions.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.product_promotions ON;
INSERT INTO dbo.product_promotions (id, product_id, promotion_id)
SELECT id, product_id, promotion_id FROM #stg_prod_prom;
SET IDENTITY_INSERT dbo.product_promotions OFF;
IF OBJECT_ID('tempdb..#stg_prod_prom') IS NOT NULL DROP TABLE #stg_prod_prom;


-- =========================================================================
-- 4. CARGA DE TRANSACCIONES PRINCIPALES (VOLUMEN GRANDE)
-- =========================================================================

-- 11. ORDERS
PRINT '11/16 Cargando orders.csv (1.000.000 filas - puede demorar 1-2 minutos)...';
IF OBJECT_ID('tempdb..#stg_orders') IS NOT NULL DROP TABLE #stg_orders;
CREATE TABLE #stg_orders (
    id BIGINT, order_number VARCHAR(50), customer_id INT, branch_id INT,
    order_type VARCHAR(30), table_id VARCHAR(50), address_id VARCHAR(50), coupon_id VARCHAR(50),
    recipient_name VARCHAR(150), recipient_phone VARCHAR(50), address_snapshot VARCHAR(MAX),
    delivery_latitude VARCHAR(50), delivery_longitude VARCHAR(50), status VARCHAR(30),
    subtotal DECIMAL(12,2), discount_amount DECIMAL(12,2), coupon_discount DECIMAL(12,2),
    delivery_fee DECIMAL(12,2), tax DECIMAL(12,2), total_amount DECIMAL(12,2),
    loyalty_earned INT, loyalty_used INT, notes VARCHAR(MAX), cancellation_reason VARCHAR(MAX),
    placed_at DATETIME2(0), completed_at VARCHAR(50), created_at VARCHAR(50), updated_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_orders FROM ''' + @RutaDataset + 'orders.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.orders ON;
INSERT INTO dbo.orders (id, order_number, customer_id, branch_id, address_id, table_id, coupon_id,
                       order_type, status, subtotal, discount_amount, coupon_discount, delivery_fee,
                       tax, total_amount, placed_at, completed_at)
SELECT id, order_number, customer_id, branch_id,
       TRY_CAST(NULLIF(address_id, '') AS INT),
       TRY_CAST(NULLIF(table_id, '') AS INT),
       TRY_CAST(NULLIF(coupon_id, '') AS INT),
       order_type, status, subtotal, discount_amount, coupon_discount, delivery_fee,
       tax, total_amount, placed_at,
       TRY_CAST(NULLIF(completed_at, '') AS DATETIME2(0))
FROM #stg_orders;
SET IDENTITY_INSERT dbo.orders OFF;
IF OBJECT_ID('tempdb..#stg_orders') IS NOT NULL DROP TABLE #stg_orders;


-- 12. ORDER_ITEMS
PRINT '12/16 Cargando order_items.csv (2.500.000 filas - puede demorar 2-3 minutos)...';
IF OBJECT_ID('tempdb..#stg_items') IS NOT NULL DROP TABLE #stg_items;
CREATE TABLE #stg_items (
    id BIGINT, order_id BIGINT, product_id INT, quantity INT,
    unit_price DECIMAL(12,2), discount DECIMAL(12,2), subtotal DECIMAL(12,2),
    special_instructions VARCHAR(MAX)
);
SET @sql = 'BULK INSERT #stg_items FROM ''' + @RutaDataset + 'order_items.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.order_items ON;
INSERT INTO dbo.order_items (id, order_id, product_id, quantity, unit_price, discount, subtotal)
SELECT id, order_id, product_id, quantity, unit_price, discount, subtotal
FROM #stg_items;
SET IDENTITY_INSERT dbo.order_items OFF;
IF OBJECT_ID('tempdb..#stg_items') IS NOT NULL DROP TABLE #stg_items;


-- 13. PAYMENTS
PRINT '13/16 Cargando payments.csv (1.000.000 filas)...';
IF OBJECT_ID('tempdb..#stg_payments') IS NOT NULL DROP TABLE #stg_payments;
CREATE TABLE #stg_payments (
    id BIGINT, order_id BIGINT, method VARCHAR(50), amount DECIMAL(12,2),
    transaction_id VARCHAR(100), status VARCHAR(30), paid_at VARCHAR(50),
    gateway_response VARCHAR(100), created_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_payments FROM ''' + @RutaDataset + 'payments.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.payments ON;
INSERT INTO dbo.payments (id, order_id, method, amount, status, paid_at)
SELECT id, order_id, method, amount, status,
       TRY_CAST(NULLIF(paid_at, '') AS DATETIME2(0))
FROM #stg_payments;
SET IDENTITY_INSERT dbo.payments OFF;
IF OBJECT_ID('tempdb..#stg_payments') IS NOT NULL DROP TABLE #stg_payments;


-- 14. DELIVERIES
PRINT '14/16 Cargando deliveries.csv (700.000 filas)...';
IF OBJECT_ID('tempdb..#stg_deliveries') IS NOT NULL DROP TABLE #stg_deliveries;
CREATE TABLE #stg_deliveries (
    id BIGINT, order_id BIGINT, delivery_person_id VARCHAR(50), status VARCHAR(30),
    assigned_at VARCHAR(50), picked_up_at VARCHAR(50), delivered_at VARCHAR(50),
    delivery_notes VARCHAR(MAX), failure_reason VARCHAR(MAX), proof_image_url VARCHAR(MAX)
);
SET @sql = 'BULK INSERT #stg_deliveries FROM ''' + @RutaDataset + 'deliveries.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.deliveries ON;
INSERT INTO dbo.deliveries (id, order_id, delivery_person_id, assigned_at, delivered_at, status)
SELECT id, order_id,
       TRY_CAST(NULLIF(delivery_person_id, '') AS INT),
       TRY_CAST(NULLIF(assigned_at, '') AS DATETIME2(0)),
       TRY_CAST(NULLIF(delivered_at, '') AS DATETIME2(0)),
       status
FROM #stg_deliveries;
SET IDENTITY_INSERT dbo.deliveries OFF;
IF OBJECT_ID('tempdb..#stg_deliveries') IS NOT NULL DROP TABLE #stg_deliveries;


-- 15. REVIEWS
PRINT '15/16 Cargando reviews.csv (600.000 filas)...';
IF OBJECT_ID('tempdb..#stg_reviews') IS NOT NULL DROP TABLE #stg_reviews;
CREATE TABLE #stg_reviews (
    id BIGINT, customer_id VARCHAR(50), product_id VARCHAR(50), order_id BIGINT,
    rating TINYINT, comment VARCHAR(1000), is_approved VARCHAR(10), created_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_reviews FROM ''' + @RutaDataset + 'reviews.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.reviews ON;
INSERT INTO dbo.reviews (id, order_id, product_id, customer_id, rating, comment, is_approved, created_at)
SELECT id, order_id,
       TRY_CAST(NULLIF(product_id, '') AS INT),
       TRY_CAST(NULLIF(customer_id, '') AS INT),
       rating, comment,
       CASE WHEN is_approved = 'True' THEN 1 ELSE 0 END,
       ISNULL(TRY_CAST(created_at AS DATETIME2(0)), SYSDATETIME())
FROM #stg_reviews;
SET IDENTITY_INSERT dbo.reviews OFF;
IF OBJECT_ID('tempdb..#stg_reviews') IS NOT NULL DROP TABLE #stg_reviews;


-- =========================================================================
-- 5. COSTOS Y RECETAS (FASE 1)
-- =========================================================================

-- 16. INGREDIENTS
PRINT '16/16 Cargando ingredients.csv y product_ingredients.csv...';
IF OBJECT_ID('tempdb..#stg_ingredients') IS NOT NULL DROP TABLE #stg_ingredients;
CREATE TABLE #stg_ingredients (
    id INT, name VARCHAR(150), unit VARCHAR(30), current_stock DECIMAL(12,4),
    reorder_level DECIMAL(12,4), cost_per_unit DECIMAL(12,4), is_active VARCHAR(10), created_at VARCHAR(50)
);
SET @sql = 'BULK INSERT #stg_ingredients FROM ''' + @RutaDataset + 'ingredients.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.ingredients ON;
INSERT INTO dbo.ingredients (id, name, unit, cost_per_unit, current_stock, reorder_level, is_active)
SELECT id, name, unit, cost_per_unit, current_stock, reorder_level,
       CASE WHEN is_active = 'True' THEN 1 ELSE 0 END
FROM #stg_ingredients;
SET IDENTITY_INSERT dbo.ingredients OFF;
IF OBJECT_ID('tempdb..#stg_ingredients') IS NOT NULL DROP TABLE #stg_ingredients;


-- PRODUCT_INGREDIENTS
IF OBJECT_ID('tempdb..#stg_prod_ing') IS NOT NULL DROP TABLE #stg_prod_ing;
CREATE TABLE #stg_prod_ing (
    id INT, product_id INT, ingredient_id INT, quantity DECIMAL(12,4), unit VARCHAR(30)
);
SET @sql = 'BULK INSERT #stg_prod_ing FROM ''' + @RutaDataset + 'product_ingredients.csv''' + @BulkOptions;
EXEC sp_executesql @sql;

SET IDENTITY_INSERT dbo.product_ingredients ON;
INSERT INTO dbo.product_ingredients (id, product_id, ingredient_id, quantity, unit)
SELECT id, product_id, ingredient_id, quantity, unit
FROM #stg_prod_ing;
SET IDENTITY_INSERT dbo.product_ingredients OFF;
IF OBJECT_ID('tempdb..#stg_prod_ing') IS NOT NULL DROP TABLE #stg_prod_ing;


-- =========================================================================
-- 6. REACTIVACIÓN DE CLAVES FORÁNEAS Y VALIDACIÓN FINAL
-- =========================================================================
PRINT '';
PRINT '-> Reactivando y validando todas las restricciones de claves foráneas...';
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
PRINT '   Claves foráneas validadas y activas.';
PRINT '';

DECLARE @HoraFin DATETIME2 = SYSDATETIME();
PRINT '=========================================================================';
PRINT 'CARGA MASIVA FINALIZADA CON ÉXITO';
PRINT 'Duración total: ' + CAST(DATEDIFF(SECOND, @HoraInicio, @HoraFin) AS VARCHAR(10)) + ' segundos';
PRINT '=========================================================================';
PRINT '';

-- Resumen de filas cargadas por tabla
SELECT 
    t.name AS [Tabla],
    p.rows AS [Total de Filas]
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
ORDER BY p.rows DESC;
GO
