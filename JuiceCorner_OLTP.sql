-- =========================================================================
-- JUICE CORNER BD - BASE DE DATOS TRANSACCIONAL (OLTP / TPS)
-- Motor: Microsoft SQL Server (T-SQL)
-- Versión Oficial Corregida y Optimizada
-- Alineado con: Decálogo Técnico ("Data Warehouse - TPS Restaurante")
--              y Dataset Kaggle ("Restaurant & Food Delivery Relational DB")
--
-- Principio de diseño: "Menos es más y mejor"
--
-- Correcciones integradas en esta versión:
--   1. Eliminación de FK recursiva redundante en customers (FK_customers_referred_by):
--      Elimina el bucle autorreferencial que bloqueaba las cargas masivas.
--      Se conserva referred_by INT NULL para alimentar es_referido en el DW.
--   2. Eliminación de FK redundante en reviews (FK_reviews_customers):
--      reviews ya se vincula a orders(id), y orders ya tiene customer_id.
--      Elimina la dependencia transitiva y el riesgo de inconsistencias.
--   3. Pagos limpios (payments):
--      payments.method almacena directamente el enumerado con restricción CHECK.
--      Sin tabla intermedia ni id_metodos artificiales en el OLTP.
--   4. Mapeo 1:1 con dataset Kaggle:
--      - orders: incluye subtotal y usa table_id para coincidir con orders.csv.
--      - ingredients: usa unit, cost_per_unit y current_stock.
--      - product_ingredients: usa quantity y unit.
--   5. Precarga de los 6 repartidores (delivery_personnel) con datos reales
--      provenientes de users.csv para evitar fallas por columnas faltantes.
--   6. Limpieza previa en orden inverso de dependencias de FK para ejecución 100% idempotente.
-- =========================================================================

IF DB_ID('JuiceCorner_OLTP') IS NULL
BEGIN
    CREATE DATABASE JuiceCorner_OLTP;
    PRINT 'Base de datos JuiceCorner_OLTP creada con éxito.';
END
GO

USE JuiceCorner_OLTP;
GO

-- -------------------------------------------------------------------------
-- LIMPIEZA PREVIA IDEMPOTENTE (Orden inverso estricto de dependencias FK)
-- -------------------------------------------------------------------------
IF OBJECT_ID('dbo.reviews', 'U') IS NOT NULL DROP TABLE dbo.reviews;
IF OBJECT_ID('dbo.deliveries', 'U') IS NOT NULL DROP TABLE dbo.deliveries;
IF OBJECT_ID('dbo.payments', 'U') IS NOT NULL DROP TABLE dbo.payments;
IF OBJECT_ID('dbo.order_items', 'U') IS NOT NULL DROP TABLE dbo.order_items;
IF OBJECT_ID('dbo.orders', 'U') IS NOT NULL DROP TABLE dbo.orders;
IF OBJECT_ID('dbo.inventory', 'U') IS NOT NULL DROP TABLE dbo.inventory;
IF OBJECT_ID('dbo.product_ingredients', 'U') IS NOT NULL DROP TABLE dbo.product_ingredients;
IF OBJECT_ID('dbo.ingredients', 'U') IS NOT NULL DROP TABLE dbo.ingredients;
IF OBJECT_ID('dbo.product_promotions', 'U') IS NOT NULL DROP TABLE dbo.product_promotions;
IF OBJECT_ID('dbo.promotions', 'U') IS NOT NULL DROP TABLE dbo.promotions;
IF OBJECT_ID('dbo.coupons', 'U') IS NOT NULL DROP TABLE dbo.coupons;
IF OBJECT_ID('dbo.delivery_personnel', 'U') IS NOT NULL DROP TABLE dbo.delivery_personnel;
IF OBJECT_ID('dbo.customer_addresses', 'U') IS NOT NULL DROP TABLE dbo.customer_addresses;
IF OBJECT_ID('dbo.customers', 'U') IS NOT NULL DROP TABLE dbo.customers;
IF OBJECT_ID('dbo.dining_tables', 'U') IS NOT NULL DROP TABLE dbo.dining_tables;
IF OBJECT_ID('dbo.delivery_zones', 'U') IS NOT NULL DROP TABLE dbo.delivery_zones;
IF OBJECT_ID('dbo.branches', 'U') IS NOT NULL DROP TABLE dbo.branches;
IF OBJECT_ID('dbo.products', 'U') IS NOT NULL DROP TABLE dbo.products;
IF OBJECT_ID('dbo.categories', 'U') IS NOT NULL DROP TABLE dbo.categories;
GO

-- =========================================================================
-- 1. CATÁLOGOS Y MAESTROS BASE
-- =========================================================================

-- 1. Categorías del menú (Kaggle: categories.csv)
CREATE TABLE dbo.categories (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    CONSTRAINT PK_categories PRIMARY KEY (id)
);
GO

-- 2. Productos de la carta (Kaggle: products.csv)
CREATE TABLE dbo.products (
    id INT IDENTITY(1,1) NOT NULL,
    category_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description VARCHAR(500) NULL,
    price DECIMAL(12,2) NOT NULL,
    discounted_price DECIMAL(12,2) NULL,
    is_seasonal BIT NOT NULL DEFAULT 0,
    is_available BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_products PRIMARY KEY (id),
    CONSTRAINT FK_products_categories FOREIGN KEY (category_id) REFERENCES dbo.categories(id)
);
GO

-- 3. Sucursales físicas (Kaggle: branches.csv)
CREATE TABLE dbo.branches (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(120) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(30) NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_branches PRIMARY KEY (id)
);
GO

-- 4. Mesas para atención en salón (Kaggle: dining_tables.csv)
CREATE TABLE dbo.dining_tables (
    id INT IDENTITY(1,1) NOT NULL,
    branch_id INT NOT NULL,
    table_number VARCHAR(20) NOT NULL,
    capacity INT NULL,
    is_available BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_dining_tables PRIMARY KEY (id),
    CONSTRAINT FK_dining_tables_branches FOREIGN KEY (branch_id) REFERENCES dbo.branches(id)
);
GO

-- 5. Zonas de entrega para delivery (Kaggle: delivery_zones.csv)
CREATE TABLE dbo.delivery_zones (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(120) NOT NULL,
    delivery_fee DECIMAL(12,2) NOT NULL,
    min_order_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    estimated_minutes INT NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_delivery_zones PRIMARY KEY (id)
);
GO

-- 6. Clientes (Kaggle: customers.csv)
-- [CAMBIO]: Se eliminó la restricción FK recursiva (FK_customers_referred_by).
-- Se mantiene referred_by INT NULL para calcular es_referido en el DW sin bloqueos de carga.
CREATE TABLE dbo.customers (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NULL,
    email VARCHAR(150) NULL,
    password_hash VARCHAR(255) NULL,
    phone_verified BIT NOT NULL DEFAULT 0,
    email_verified BIT NOT NULL DEFAULT 0,
    referral_code VARCHAR(50) NULL,
    referred_by INT NULL,                   -- Sin FK recursiva para permitir importación masiva directa
    loyalty_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_customers PRIMARY KEY (id)
);
GO

-- 7. Direcciones registradas de clientes (Kaggle: customer_addresses.csv)
CREATE TABLE dbo.customer_addresses (
    id INT IDENTITY(1,1) NOT NULL,
    customer_id INT NOT NULL,
    zone_id INT NOT NULL,
    address_line VARCHAR(300) NOT NULL,
    is_default BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_customer_addresses PRIMARY KEY (id),
    CONSTRAINT FK_customer_addresses_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(id),
    CONSTRAINT FK_customer_addresses_zones FOREIGN KEY (zone_id) REFERENCES dbo.delivery_zones(id)
);
GO

-- 8. Personal de reparto (Delivery personnel)
CREATE TABLE dbo.delivery_personnel (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    vehicle_number VARCHAR(50) NULL,
    license_number VARCHAR(80) NOT NULL,
    availability BIT NOT NULL DEFAULT 1,
    current_latitude DECIMAL(10,7) NULL,
    current_longitude DECIMAL(10,7) NULL,
    CONSTRAINT PK_delivery_personnel PRIMARY KEY (id)
);
GO

-- 9. Cupones de descuento (Kaggle: coupons.csv)
CREATE TABLE dbo.coupons (
    id INT IDENTITY(1,1) NOT NULL,
    code VARCHAR(50) NOT NULL,
    discount_type VARCHAR(30) NOT NULL,      -- 'percent', 'fixed'
    discount_value DECIMAL(12,2) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_coupons PRIMARY KEY (id),
    CONSTRAINT UQ_coupons_code UNIQUE (code),
    CONSTRAINT CK_coupons_discount_type CHECK (discount_type IN ('percent', 'fixed'))
);
GO

-- 10. Campañas de promociones (Kaggle: promotions.csv)
CREATE TABLE dbo.promotions (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(150) NOT NULL,
    discount_percentage DECIMAL(5,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_promotions PRIMARY KEY (id)
);
GO

-- 11. Relación de productos en promoción (Kaggle: product_promotions.csv)
CREATE TABLE dbo.product_promotions (
    id INT IDENTITY(1,1) NOT NULL,
    product_id INT NOT NULL,
    promotion_id INT NOT NULL,
    CONSTRAINT PK_product_promotions PRIMARY KEY (id),
    CONSTRAINT FK_prod_prom_product FOREIGN KEY (product_id) REFERENCES dbo.products(id),
    CONSTRAINT FK_prod_prom_promotion FOREIGN KEY (promotion_id) REFERENCES dbo.promotions(id)
);
GO


-- =========================================================================
-- 2. TRANSACCIONES PRINCIPALES (PEDIDOS, DETALLE, PAGOS Y ENTREGAS)
-- =========================================================================

-- 12. Cabecera de pedidos (Kaggle: orders.csv)
-- Incluye subtotal y table_id para alineación directa 1:1 con orders.csv
CREATE TABLE dbo.orders (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_number VARCHAR(50) NOT NULL,
    customer_id INT NULL,
    branch_id INT NOT NULL,
    address_id INT NULL,
    table_id INT NULL,                       -- table_id en el CSV (FK hacia dining_tables)
    coupon_id INT NULL,
    order_type VARCHAR(30) NOT NULL,         -- 2 canales exclusivos: 'dine_in' (Local, 45,0 %) y 'delivery' (55,0 %)
    status VARCHAR(30) NOT NULL,             -- estados reales del TPS
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    coupon_discount DECIMAL(12,2) NOT NULL DEFAULT 0,
    delivery_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    placed_at DATETIME2(0) NOT NULL,
    completed_at DATETIME2(0) NULL,
    CONSTRAINT PK_orders PRIMARY KEY (id),
    CONSTRAINT UQ_orders_number UNIQUE (order_number),
    CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(id),
    CONSTRAINT FK_orders_branches FOREIGN KEY (branch_id) REFERENCES dbo.branches(id),
    CONSTRAINT FK_orders_addresses FOREIGN KEY (address_id) REFERENCES dbo.customer_addresses(id),
    CONSTRAINT FK_orders_tables FOREIGN KEY (table_id) REFERENCES dbo.dining_tables(id),
    CONSTRAINT FK_orders_coupons FOREIGN KEY (coupon_id) REFERENCES dbo.coupons(id),
    CONSTRAINT CK_orders_order_type CHECK (order_type IN ('dine_in', 'delivery')),
    CONSTRAINT CK_orders_status CHECK (status IN ('pending', 'confirmed', 'in_prep', 'ready',
                                                  'served', 'out_for_delivery', 'delivered',
                                                  'completed', 'cancelled'))
);
GO

-- 13. Detalle de líneas de pedido (Kaggle: order_items.csv)
-- Representa el grano de la tabla de hechos FACT_VENTAS en el DW
CREATE TABLE dbo.order_items (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount DECIMAL(12,2) NOT NULL DEFAULT 0,
    subtotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_order_items PRIMARY KEY (id),
    CONSTRAINT FK_order_items_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(id),
    CONSTRAINT FK_order_items_products FOREIGN KEY (product_id) REFERENCES dbo.products(id)
);
GO

-- 14. Pagos del pedido (Kaggle: payments.csv)
-- [DISEÑO LIMPIO]: Sin tabla payment_methods ni id_metodos artificiales en el OLTP.
-- method guarda el valor del enumerado con restricción CHECK de integridad.
CREATE TABLE dbo.payments (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    method VARCHAR(50) NOT NULL,             -- Dominio de los 6 métodos del TPS
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(30) NOT NULL,             -- 'paid' = pago exitoso
    paid_at DATETIME2(0) NULL,
    CONSTRAINT PK_payments PRIMARY KEY (id),
    CONSTRAINT FK_payments_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(id),
    CONSTRAINT CK_payments_method CHECK (method IN ('cash', 'card', 'bkash', 'nagad', 'rocket', 'gateway')),
    CONSTRAINT CK_payments_status CHECK (status IN ('pending', 'paid', 'failed', 'refunded'))
);
GO

-- 15. Despachos y entregas de delivery (Kaggle: deliveries.csv)
CREATE TABLE dbo.deliveries (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    delivery_person_id INT NULL,             -- NULL si el pedido aún no tiene repartidor asignado
    assigned_at DATETIME2(0) NULL,
    delivered_at DATETIME2(0) NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT PK_deliveries PRIMARY KEY (id),
    CONSTRAINT UQ_deliveries_order UNIQUE (order_id),   -- Máximo una entrega por pedido
    CONSTRAINT FK_deliveries_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(id),
    CONSTRAINT FK_deliveries_personnel FOREIGN KEY (delivery_person_id) REFERENCES dbo.delivery_personnel(id),
    CONSTRAINT CK_deliveries_status CHECK (status IN ('assigned', 'picked_up', 'on_way', 'delivered', 'failed'))
);
GO

-- 16. Reseñas y calificaciones (Kaggle: reviews.csv)
CREATE TABLE dbo.reviews (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    product_id INT NULL,
    customer_id INT NULL,                   -- Sin FK física redundante hacia customers
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment VARCHAR(1000) NULL,
    is_approved BIT NOT NULL DEFAULT 0,
    created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_reviews PRIMARY KEY (id),
    CONSTRAINT FK_reviews_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(id),
    CONSTRAINT FK_reviews_products FOREIGN KEY (product_id) REFERENCES dbo.products(id)
);
GO


-- =========================================================================
-- 3. COSTOS, RECETAS E INVENTARIO (FASE 1)
-- =========================================================================

-- 17. Insumos (Kaggle: ingredients.csv)
CREATE TABLE dbo.ingredients (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(150) NOT NULL,
    unit VARCHAR(30) NOT NULL,              -- kg, ltr, pcs (unit en Kaggle)
    cost_per_unit DECIMAL(12,4) NOT NULL,   -- cost_per_unit en Kaggle
    current_stock DECIMAL(12,4) NOT NULL DEFAULT 0,
    reorder_level DECIMAL(12,4) NOT NULL DEFAULT 0,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_ingredients PRIMARY KEY (id)
);
GO

-- 18. Recetas por producto (Kaggle: product_ingredients.csv)
CREATE TABLE dbo.product_ingredients (
    id INT IDENTITY(1,1) NOT NULL,
    product_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity DECIMAL(12,4) NOT NULL,        -- quantity en Kaggle
    unit VARCHAR(30) NULL,
    CONSTRAINT PK_product_ingredients PRIMARY KEY (id),
    CONSTRAINT FK_prod_ing_product FOREIGN KEY (product_id) REFERENCES dbo.products(id),
    CONSTRAINT FK_prod_ing_ingredient FOREIGN KEY (ingredient_id) REFERENCES dbo.ingredients(id)
);
GO

-- 19. Inventario por sucursal
CREATE TABLE dbo.inventory (
    id INT IDENTITY(1,1) NOT NULL,
    branch_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    stock_quantity DECIMAL(14,4) NOT NULL DEFAULT 0,
    updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_inventory PRIMARY KEY (id),
    CONSTRAINT FK_inventory_branches FOREIGN KEY (branch_id) REFERENCES dbo.branches(id),
    CONSTRAINT FK_inventory_ingredients FOREIGN KEY (ingredient_id) REFERENCES dbo.ingredients(id)
);
GO


-- =========================================================================
-- 4. PRECARGA OFICIAL: LOS 6 REPARTIDORES REALES DE KAGGLE
-- (Cruzados desde delivery_personnel.csv + users.csv para disponibilidad inmediata)
-- =========================================================================
SET IDENTITY_INSERT dbo.delivery_personnel ON;
IF NOT EXISTS (SELECT 1 FROM dbo.delivery_personnel WHERE id = 1)
BEGIN
    INSERT INTO dbo.delivery_personnel (id, name, phone, vehicle_type, vehicle_number, license_number, availability, current_latitude, current_longitude)
    VALUES 
    (1, 'Robin Mia',      '+8801700000015', 'Motorcycle', 'DHAKA-METRO-HA-11-2233', 'DL-8823901', 1, 23.7465000, 90.3745000),
    (2, 'Sohel Rana',     '+8801700000016', 'Bicycle',    'N/A',                   'N/A',        0, 23.7450000, 90.3730000),
    (3, 'Limon Hossain',  '+8801700000017', 'Motorcycle', 'DHAKA-METRO-LA-12-4455', 'DL-8823902', 1, 23.7810000, 90.4170000),
    (4, 'Parvez Alam',    '+8801700000018', 'Motorcycle', 'DHAKA-METRO-HA-13-6677', 'DL-8823903', 0, 23.7800000, 90.4150000),
    (5, 'Sharif Uddin',   '+8801700000019', 'Bicycle',    'N/A',                   'N/A',        1, 23.7940000, 90.4050000),
    (6, 'Jahangir Alam',  '+8801700000020', 'Motorcycle', 'DHAKA-METRO-LA-14-8899', 'DL-8823904', 0, 23.7930000, 90.4030000);
    PRINT '6 repartidores precargados en delivery_personnel.';
END
SET IDENTITY_INSERT dbo.delivery_personnel OFF;
GO

PRINT '=========================================================';
PRINT 'Base de datos JuiceCorner_OLTP creada y configurada.';
PRINT 'Lista para recibir la carga de los CSV del dataset Kaggle.';
PRINT '=========================================================';
GO
