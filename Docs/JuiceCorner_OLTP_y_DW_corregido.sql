-- ========================================================================= 
-- https://claude.ai/share/932ecb85-7720-4af1-b2c7-42bc8a68c8e3
-- JUICE CORNER - SCRIPTS CORREGIDOS SEGÚN EL DECÁLOGO
-- "Data Warehouse – Sistema TPS de Pedidos de Restaurante"
-- Motor: Microsoft SQL Server (T-SQL)
--
-- Contenido:
--   SCRIPT 1: Base transaccional  (JuiceCorner_OLTP)
--   SCRIPT 2: Data Warehouse      (JuiceCorner_DW) - modelo estrella
--
-- Cambios respecto a la versión original (marcados con [CAMBIO]):
--   OLTP: dominios de valores reales (CHECK) en order_type, status,
--         payments.method / payments.status y deliveries.status;
--         deliveries.delivery_person_id admite NULL y order_id es UNIQUE.
--   DW:   carga de los valores del enumerado en DIM_METODO_PAGO (el decálogo
--         exige cargarla una vez) y CHECK de calificacion (1 a 5).
--         Se documenta la fórmula correcta de monto_neto (ver FACT_VENTAS).
-- =========================================================================


-- =========================================================================
-- SCRIPT 1: BASE DE DATOS TRANSACCIONAL (OLTP / TPS) - JUICE CORNER BD
-- =========================================================================

IF DB_ID('JuiceCorner_OLTP') IS NULL
    CREATE DATABASE JuiceCorner_OLTP;
GO

USE JuiceCorner_OLTP;
GO

-- 1. Categorías de productos
CREATE TABLE dbo.categories (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    CONSTRAINT PK_categories PRIMARY KEY (id)
);

-- 2. Productos de la carta
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

-- 3. Sucursales físicas
CREATE TABLE dbo.branches (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(300) NOT NULL,
    phone VARCHAR(30) NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_branches PRIMARY KEY (id)
);

-- 4. Mesas para atención en salón
CREATE TABLE dbo.dining_tables (
    id INT IDENTITY(1,1) NOT NULL,
    branch_id INT NOT NULL,
    table_number VARCHAR(20) NOT NULL,
    capacity INT NULL,
    is_available BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_dining_tables PRIMARY KEY (id),
    CONSTRAINT FK_dining_tables_branches FOREIGN KEY (branch_id) REFERENCES dbo.branches(id)
);

-- 5. Zonas de entrega (Delivery)
CREATE TABLE dbo.delivery_zones (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(120) NOT NULL,
    delivery_fee DECIMAL(12,2) NOT NULL,
    min_order_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    estimated_minutes INT NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_delivery_zones PRIMARY KEY (id)
);

-- 6. Clientes
CREATE TABLE dbo.customers (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NULL,
    email VARCHAR(150) NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_verified BIT NOT NULL DEFAULT 0,
    email_verified BIT NOT NULL DEFAULT 0,
    referral_code VARCHAR(50) NULL,
    referred_by INT NULL,
    loyalty_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_customers PRIMARY KEY (id),
    CONSTRAINT FK_customers_referred_by FOREIGN KEY (referred_by) REFERENCES dbo.customers(id)
);

-- 7. Direcciones de clientes (puente hacia delivery_zones)
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

-- 9. Cupones de descuento
CREATE TABLE dbo.coupons (
    id INT IDENTITY(1,1) NOT NULL,
    code VARCHAR(50) NOT NULL,
    discount_type VARCHAR(30) NOT NULL,      -- 'percent', 'fixed'
    discount_value DECIMAL(12,2) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_coupons PRIMARY KEY (id),
    CONSTRAINT UQ_coupons_code UNIQUE (code),
    CONSTRAINT CK_coupons_discount_type CHECK (discount_type IN ('percent', 'fixed'))   -- [CAMBIO]
);

-- 10. Campañas de promociones
CREATE TABLE dbo.promotions (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(150) NOT NULL,
    discount_percentage DECIMAL(5,2) NULL,
    start_date DATETIME2(0) NOT NULL,
    end_date DATETIME2(0) NOT NULL,
    is_active BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_promotions PRIMARY KEY (id)
);

-- 11. Relación de productos en promoción
CREATE TABLE dbo.product_promotions (
    id INT IDENTITY(1,1) NOT NULL,
    product_id INT NOT NULL,
    promotion_id INT NOT NULL,
    CONSTRAINT PK_product_promotions PRIMARY KEY (id),
    CONSTRAINT FK_prod_prom_product FOREIGN KEY (product_id) REFERENCES dbo.products(id),
    CONSTRAINT FK_prod_prom_promotion FOREIGN KEY (promotion_id) REFERENCES dbo.promotions(id)
);

-- 12. Cabecera de pedidos (Orders)
CREATE TABLE dbo.orders (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_number VARCHAR(50) NOT NULL,
    customer_id INT NULL,
    branch_id INT NOT NULL,
    address_id INT NULL,
    dining_table_id INT NULL,
    coupon_id INT NULL,
    order_type VARCHAR(30) NOT NULL,         -- 2 canales exclusivos: 'dine_in' (Local, 45,0 %) y 'delivery' (55,0 %)
    status VARCHAR(30) NOT NULL,             -- ver CHECK: 9 estados del TPS
    placed_at DATETIME2(0) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    coupon_discount DECIMAL(12,2) NOT NULL DEFAULT 0,
    delivery_fee DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_orders PRIMARY KEY (id),
    CONSTRAINT UQ_orders_number UNIQUE (order_number),
    CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(id),
    CONSTRAINT FK_orders_branches FOREIGN KEY (branch_id) REFERENCES dbo.branches(id),
    CONSTRAINT FK_orders_addresses FOREIGN KEY (address_id) REFERENCES dbo.customer_addresses(id),
    CONSTRAINT FK_orders_tables FOREIGN KEY (dining_table_id) REFERENCES dbo.dining_tables(id),
    CONSTRAINT FK_orders_coupons FOREIGN KEY (coupon_id) REFERENCES dbo.coupons(id),
    -- [CAMBIO] Dominios reales del TPS (en los datos solo aparecen dine_in y delivery;
    --          takeaway se mantiene porque el decálogo contempla pedidos para llevar)
    CONSTRAINT CK_orders_order_type CHECK (order_type IN ('dine_in', 'delivery')),
    CONSTRAINT CK_orders_status CHECK (status IN ('pending', 'confirmed', 'in_prep', 'ready',
                                                  'served', 'out_for_delivery', 'delivered',
                                                  'completed', 'cancelled'))
);

-- 13. Detalle de líneas de pedido (Order Items)
-- Nota: en el TPS, subtotal = quantity * unit_price - discount (ya viene neto del descuento de línea)
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

-- 14. Pagos del pedido (Payments)
CREATE TABLE dbo.payments (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    method VARCHAR(50) NOT NULL,             -- Enumerado payment_method
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(30) NOT NULL,             -- 'paid' = pago exitoso
    paid_at DATETIME2(0) NULL,
    CONSTRAINT PK_payments PRIMARY KEY (id),
    CONSTRAINT FK_payments_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(id),
    -- [CAMBIO] Dominios reales: el estado exitoso es 'paid' (no 'completed')
    CONSTRAINT CK_payments_method CHECK (method IN ('cash', 'card', 'bkash', 'nagad', 'rocket', 'gateway')),
    CONSTRAINT CK_payments_status CHECK (status IN ('pending', 'paid', 'failed', 'refunded'))
);

-- 15. Despachos y entregas (Deliveries)
CREATE TABLE dbo.deliveries (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    delivery_person_id INT NULL,             -- [CAMBIO] admite NULL (pedido aún sin repartidor asignado)
    assigned_at DATETIME2(0) NULL,
    delivered_at DATETIME2(0) NULL,
    status VARCHAR(30) NOT NULL,
    CONSTRAINT PK_deliveries PRIMARY KEY (id),
    CONSTRAINT UQ_deliveries_order UNIQUE (order_id),   -- [CAMBIO] una entrega por pedido (evita duplicar filas en el ETL)
    CONSTRAINT FK_deliveries_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(id),
    CONSTRAINT FK_deliveries_personnel FOREIGN KEY (delivery_person_id) REFERENCES dbo.delivery_personnel(id),
    CONSTRAINT CK_deliveries_status CHECK (status IN ('assigned', 'picked_up', 'on_way', 'delivered', 'failed'))   -- [CAMBIO]
);

-- 16. Reseñas y calificaciones (Reviews)
CREATE TABLE dbo.reviews (
    id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    product_id INT NULL,
    customer_id INT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment VARCHAR(1000) NULL,
    is_approved BIT NOT NULL DEFAULT 0,
    created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_reviews PRIMARY KEY (id),
    CONSTRAINT FK_reviews_orders FOREIGN KEY (order_id) REFERENCES dbo.orders(id),
    CONSTRAINT FK_reviews_products FOREIGN KEY (product_id) REFERENCES dbo.products(id),
    CONSTRAINT FK_reviews_customers FOREIGN KEY (customer_id) REFERENCES dbo.customers(id)
);

-- 17. Tablas de costos, recetas e inventario (Fase 1 del proyecto)
CREATE TABLE dbo.ingredients (
    id INT IDENTITY(1,1) NOT NULL,
    name VARCHAR(150) NOT NULL,
    unit_of_measure VARCHAR(30) NOT NULL,
    unit_cost DECIMAL(12,4) NOT NULL,
    CONSTRAINT PK_ingredients PRIMARY KEY (id)
);

CREATE TABLE dbo.product_ingredients (
    id INT IDENTITY(1,1) NOT NULL,
    product_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity_required DECIMAL(12,4) NOT NULL,
    CONSTRAINT PK_product_ingredients PRIMARY KEY (id),
    CONSTRAINT FK_prod_ing_product FOREIGN KEY (product_id) REFERENCES dbo.products(id),
    CONSTRAINT FK_prod_ing_ingredient FOREIGN KEY (ingredient_id) REFERENCES dbo.ingredients(id)
);

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
-- SCRIPT 2: DATA WAREHOUSE (MODELO ESTRELLA) - JUICE CORNER DW
-- =========================================================================

IF DB_ID('JuiceCorner_DW') IS NULL
    CREATE DATABASE JuiceCorner_DW;
GO

USE JuiceCorner_DW;
GO

-- 1. DIM_TIEMPO (Grano: un registro por mes, formato AAAAMM)
CREATE TABLE dbo.DIM_TIEMPO (
    tiempo_key INT NOT NULL,                 -- Formato AAAAMM (ej. 202609)
    mes TINYINT NOT NULL,                    -- 1 a 12
    nombre_mes VARCHAR(20) NOT NULL,
    semestre TINYINT NOT NULL,               -- 1 a 2
    [año] SMALLINT NOT NULL,
    CONSTRAINT PK_DIM_TIEMPO PRIMARY KEY (tiempo_key),
    CONSTRAINT CK_DIM_TIEMPO_mes CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT CK_DIM_TIEMPO_semestre CHECK (semestre IN (1, 2))
);

-- 2. DIM_CLIENTE (Excluye password_hash, loyalty_balance y referral_code)
CREATE TABLE dbo.DIM_CLIENTE (
    cliente_key INT IDENTITY(1,1) NOT NULL,
    customer_id_nk INT NOT NULL,             -- Clave natural del TPS (customers.id)
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NULL,
    email VARCHAR(150) NULL,
    phone_verified CHAR(1) NOT NULL,         -- 'S' / 'N'
    email_verified CHAR(1) NOT NULL,         -- 'S' / 'N'
    es_referido CHAR(1) NOT NULL,            -- 'S' / 'N' (referred_by IS NOT NULL)
    fecha_registro DATETIME2(0) NULL,
    CONSTRAINT PK_DIM_CLIENTE PRIMARY KEY (cliente_key),
    CONSTRAINT UQ_DIM_CLIENTE_nk UNIQUE (customer_id_nk),
    CONSTRAINT CK_DIM_CLIENTE_phone_ver CHECK (phone_verified IN ('S', 'N')),
    CONSTRAINT CK_DIM_CLIENTE_email_ver CHECK (email_verified IN ('S', 'N')),
    CONSTRAINT CK_DIM_CLIENTE_referido CHECK (es_referido IN ('S', 'N'))
);

-- 3. DIM_PRODUCTO (Desnormaliza products y categories; excluye precios de lista)
CREATE TABLE dbo.DIM_PRODUCTO (
    producto_key INT IDENTITY(1,1) NOT NULL,
    product_id_nk INT NOT NULL,              -- Clave natural del TPS (products.id)
    name VARCHAR(150) NOT NULL,
    description VARCHAR(500) NULL,
    is_seasonal CHAR(1) NOT NULL,            -- 'S' / 'N'
    is_available CHAR(1) NOT NULL,           -- 'S' / 'N'
    category_name VARCHAR(100) NOT NULL,
    category_description VARCHAR(500) NULL,
    CONSTRAINT PK_DIM_PRODUCTO PRIMARY KEY (producto_key),
    CONSTRAINT UQ_DIM_PRODUCTO_nk UNIQUE (product_id_nk),
    CONSTRAINT CK_DIM_PRODUCTO_seasonal CHECK (is_seasonal IN ('S', 'N')),
    CONSTRAINT CK_DIM_PRODUCTO_available CHECK (is_available IN ('S', 'N'))
);

-- 4. DIM_SUCURSAL (Origen: branches)
CREATE TABLE dbo.DIM_SUCURSAL (
    sucursal_key INT IDENTITY(1,1) NOT NULL,
    branch_id_nk INT NOT NULL,               -- Clave natural del TPS (branches.id)
    name VARCHAR(150) NOT NULL,
    address VARCHAR(300) NOT NULL,
    phone VARCHAR(30) NULL,
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL,
    is_active CHAR(1) NOT NULL,              -- 'S' / 'N'
    CONSTRAINT PK_DIM_SUCURSAL PRIMARY KEY (sucursal_key),
    CONSTRAINT UQ_DIM_SUCURSAL_nk UNIQUE (branch_id_nk),
    CONSTRAINT CK_DIM_SUCURSAL_active CHECK (is_active IN ('S', 'N'))
);

-- 5. DIM_ZONA_ENTREGA (Origen: delivery_zones vía customer_addresses)
CREATE TABLE dbo.DIM_ZONA_ENTREGA (
    zona_key INT IDENTITY(1,1) NOT NULL,
    zone_id_nk INT NOT NULL,                 -- Clave natural del TPS (delivery_zones.id)
    name VARCHAR(120) NOT NULL,
    tarifa_base DECIMAL(12,2) NOT NULL,
    min_order_amount DECIMAL(12,2) NOT NULL,
    estimated_minutes INT NOT NULL,
    is_active CHAR(1) NOT NULL,              -- 'S' / 'N'
    CONSTRAINT PK_DIM_ZONA_ENTREGA PRIMARY KEY (zona_key),
    CONSTRAINT UQ_DIM_ZONA_ENTREGA_nk UNIQUE (zone_id_nk),
    CONSTRAINT CK_DIM_ZONA_active CHECK (is_active IN ('S', 'N'))
);

-- 6. DIM_REPARTIDOR (Excluye availability, coordenadas en vivo y license_number)
CREATE TABLE dbo.DIM_REPARTIDOR (
    repartidor_key INT IDENTITY(1,1) NOT NULL,
    delivery_person_id_nk INT NOT NULL,      -- Clave natural del TPS (delivery_personnel.id)
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30) NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    vehicle_number VARCHAR(50) NULL,
    CONSTRAINT PK_DIM_REPARTIDOR PRIMARY KEY (repartidor_key),
    CONSTRAINT UQ_DIM_REPARTIDOR_nk UNIQUE (delivery_person_id_nk)
);

-- 7. DIM_METODO_PAGO (Origen: dominio del enumerado payments.method)
CREATE TABLE dbo.DIM_METODO_PAGO (
    metodo_pago_key INT IDENTITY(1,1) NOT NULL,
    codigo_metodo VARCHAR(50) NOT NULL,      -- Clave natural del enumerado payment_method
    nombre_metodo VARCHAR(100) NOT NULL,
    CONSTRAINT PK_DIM_METODO_PAGO PRIMARY KEY (metodo_pago_key),
    CONSTRAINT UQ_DIM_METODO_PAGO_cod UNIQUE (codigo_metodo)
);

-- 8. TABLA DE HECHOS: FACT_VENTAS (Grano: una fila por línea de pedido order_items.id)
CREATE TABLE dbo.FACT_VENTAS (
    venta_key BIGINT IDENTITY(1,1) NOT NULL,

    -- Dimensiones degeneradas (identificadores transaccionales)
    order_item_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,
    order_number VARCHAR(50) NOT NULL,

    -- Claves foráneas hacia dimensiones (claves sustitutas)
    tiempo_key INT NOT NULL,
    cliente_key INT NOT NULL,
    producto_key INT NOT NULL,
    sucursal_key INT NOT NULL,
    zona_key INT NOT NULL,
    repartidor_key INT NOT NULL,
    metodo_pago_key INT NOT NULL,

    -- Atributos degenerados adicionales y banderas
    tipo_pedido VARCHAR(30) NOT NULL,
    estado_pedido VARCHAR(30) NOT NULL,
    codigo_cupon VARCHAR(50) NULL,
    numero_mesa VARCHAR(20) NULL,
    en_promocion CHAR(1) NOT NULL,           -- 'S' / 'N'

    -- Medidas de línea y medidas prorrateadas del pedido
    -- peso de línea = subtotal / Σ subtotal del pedido
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    descuento_linea DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    descuento_pedido_prorr DECIMAL(12,4) NOT NULL,
    descuento_cupon_prorr DECIMAL(12,4) NOT NULL,
    costo_envio_prorr DECIMAL(12,4) NOT NULL,
    impuesto_prorr DECIMAL(12,4) NOT NULL,
    -- [CAMBIO - IMPORTANTE] Fórmula verificada contra los datos del TPS (muestra de 100.000 pedidos):
    --   monto_neto = subtotal - descuento_cupon_prorr + costo_envio_prorr + impuesto_prorr
    -- order_items.subtotal ya viene neto de order_items.discount y orders.discount_amount
    -- es igual a la suma de esos descuentos de línea. Por eso descuento_pedido_prorr es
    -- informativo: si también se restara, el descuento se contaría dos veces y la
    -- auditoría (Σ monto_neto vs orders.total_amount) fallaría en la mayoría de pedidos.
    monto_neto DECIMAL(12,4) NOT NULL,

    -- Medidas de satisfacción y logística
    calificacion TINYINT NULL,               -- Nulo cuando no hay reseña aprobada
    minutos_entrega INT NULL,                -- Replicado por pedido; analizar con AVG sobre pedidos distintos
    line_count TINYINT NOT NULL DEFAULT 1,   -- Constante = 1

    CONSTRAINT PK_FACT_VENTAS PRIMARY KEY (venta_key),
    CONSTRAINT UQ_FACT_VENTAS_order_item UNIQUE (order_item_id),
    CONSTRAINT CK_FACT_VENTAS_promocion CHECK (en_promocion IN ('S', 'N')),
    CONSTRAINT CK_FACT_VENTAS_line_count CHECK (line_count = 1),
    CONSTRAINT CK_FACT_VENTAS_calificacion CHECK (calificacion IS NULL OR calificacion BETWEEN 1 AND 5),   -- [CAMBIO]
    CONSTRAINT FK_FACT_VENTAS_TIEMPO FOREIGN KEY (tiempo_key) REFERENCES dbo.DIM_TIEMPO(tiempo_key),
    CONSTRAINT FK_FACT_VENTAS_CLIENTE FOREIGN KEY (cliente_key) REFERENCES dbo.DIM_CLIENTE(cliente_key),
    CONSTRAINT FK_FACT_VENTAS_PRODUCTO FOREIGN KEY (producto_key) REFERENCES dbo.DIM_PRODUCTO(producto_key),
    CONSTRAINT FK_FACT_VENTAS_SUCURSAL FOREIGN KEY (sucursal_key) REFERENCES dbo.DIM_SUCURSAL(sucursal_key),
    CONSTRAINT FK_FACT_VENTAS_ZONA FOREIGN KEY (zona_key) REFERENCES dbo.DIM_ZONA_ENTREGA(zona_key),
    CONSTRAINT FK_FACT_VENTAS_REPARTIDOR FOREIGN KEY (repartidor_key) REFERENCES dbo.DIM_REPARTIDOR(repartidor_key),
    CONSTRAINT FK_FACT_VENTAS_METODO_PAGO FOREIGN KEY (metodo_pago_key) REFERENCES dbo.DIM_METODO_PAGO(metodo_pago_key)
);

-- 9. TABLA DE AUDITORÍA DE ETL (Validación Σ monto_neto vs orders.total_amount)
CREATE TABLE dbo.AUDITORIA_CUADRE_PEDIDOS (
    auditoria_id BIGINT IDENTITY(1,1) NOT NULL,
    order_id BIGINT NOT NULL,
    order_number VARCHAR(50) NOT NULL,
    total_amount_tps DECIMAL(12,4) NOT NULL,
    suma_monto_neto_dw DECIMAL(12,4) NOT NULL,
    diferencia DECIMAL(12,4) NOT NULL,
    fecha_auditoria DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_AUDITORIA_CUADRE PRIMARY KEY (auditoria_id)
);

-- Índices analíticos sobre claves foráneas y order_id (para COUNT(DISTINCT order_id))
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_tiempo ON dbo.FACT_VENTAS(tiempo_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_producto ON dbo.FACT_VENTAS(producto_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_sucursal ON dbo.FACT_VENTAS(sucursal_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_cliente ON dbo.FACT_VENTAS(cliente_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_zona ON dbo.FACT_VENTAS(zona_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_repartidor ON dbo.FACT_VENTAS(repartidor_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_metodo_pago ON dbo.FACT_VENTAS(metodo_pago_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_order_id ON dbo.FACT_VENTAS(order_id);
GO

-- =========================================================================
-- CARGA DE MIEMBROS ESPECIALES (CLAVE -1), DOMINIO DE PAGO Y CALENDARIO MENSUAL
-- =========================================================================

-- Miembro -1 en DIM_CLIENTE: "Cliente invitado"
SET IDENTITY_INSERT dbo.DIM_CLIENTE ON;
INSERT INTO dbo.DIM_CLIENTE (cliente_key, customer_id_nk, name, phone, email, phone_verified, email_verified, es_referido, fecha_registro)
VALUES (-1, -1, 'Cliente invitado', NULL, NULL, 'N', 'N', 'N', NULL);
SET IDENTITY_INSERT dbo.DIM_CLIENTE OFF;

-- Miembro -1 en DIM_ZONA_ENTREGA: "No aplica" (para pedidos en salón / local)
SET IDENTITY_INSERT dbo.DIM_ZONA_ENTREGA ON;
INSERT INTO dbo.DIM_ZONA_ENTREGA (zona_key, zone_id_nk, name, tarifa_base, min_order_amount, estimated_minutes, is_active)
VALUES (-1, -1, 'No aplica (Consumo en Local)', 0.00, 0.00, 0, 'N');
SET IDENTITY_INSERT dbo.DIM_ZONA_ENTREGA OFF;

-- Miembro -1 en DIM_REPARTIDOR: "No aplica" (para pedidos en salón / local)
SET IDENTITY_INSERT dbo.DIM_REPARTIDOR ON;
INSERT INTO dbo.DIM_REPARTIDOR (repartidor_key, delivery_person_id_nk, name, phone, vehicle_type, vehicle_number)
VALUES (-1, -1, 'No aplica (Consumo en Local)', NULL, 'No aplica', NULL);
SET IDENTITY_INSERT dbo.DIM_REPARTIDOR OFF;

-- Miembro -1 en DIM_METODO_PAGO: "Sin pago" (para pedidos sin pago exitoso)
SET IDENTITY_INSERT dbo.DIM_METODO_PAGO ON;
INSERT INTO dbo.DIM_METODO_PAGO (metodo_pago_key, codigo_metodo, nombre_metodo)
VALUES (-1, 'SIN_PAGO', 'Sin pago');
SET IDENTITY_INSERT dbo.DIM_METODO_PAGO OFF;

-- [CAMBIO] Carga única de DIM_METODO_PAGO con los valores del enumerado payment_method
INSERT INTO dbo.DIM_METODO_PAGO (codigo_metodo, nombre_metodo)
VALUES ('cash',    'Efectivo'),
       ('card',    'Tarjeta'),
       ('bkash',   'bKash'),
       ('nagad',   'Nagad'),
       ('rocket',  'Rocket'),
       ('gateway', 'Pasarela de pago');

-- Poblamiento continuo de DIM_TIEMPO (todos los meses de 2025 y 2026)
;WITH Meses AS (
    SELECT CAST('2025-01-01' AS DATE) AS FechaMes
    UNION ALL
    SELECT DATEADD(MONTH, 1, FechaMes)
    FROM Meses
    WHERE FechaMes < '2026-12-01'
)
INSERT INTO dbo.DIM_TIEMPO (tiempo_key, mes, nombre_mes, semestre, [año])
SELECT
    YEAR(FechaMes) * 100 + MONTH(FechaMes) AS tiempo_key,
    MONTH(FechaMes) AS mes,
    CASE MONTH(FechaMes)
        WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
    END AS nombre_mes,
    CASE WHEN MONTH(FechaMes) <= 6 THEN 1 ELSE 2 END AS semestre,
    YEAR(FechaMes) AS [año]
FROM Meses;
GO
