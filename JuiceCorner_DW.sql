-- =========================================================================
-- PROYECTO: JUICE CORNER BD - DATA WAREHOUSE (SISTEMA TPS DE RESTAURANTE)
-- ARCHIVO: JuiceCorner_DW.sql
-- DESCRIPCIÓN: Modelo Dimensional en Estrella Puro (1 Hecho + 7 Dimensiones)
--              Construido y verificado estrictamente según el Decálogo Técnico
--              y en total alineación 1:1 con JuiceCorner_OLTP.sql.
-- MOTOR: Microsoft SQL Server (T-SQL)
-- =========================================================================

-- 0. CREACIÓN DE LA BASE DE DATOS DEL DATA WAREHOUSE
IF DB_ID('JuiceCorner_DW') IS NULL
BEGIN
    CREATE DATABASE JuiceCorner_DW;
    PRINT 'Base de datos JuiceCorner_DW creada con éxito.';
END
GO

USE JuiceCorner_DW;
GO

-- Esquema auxiliar para segregar tablas de control/ETL y no contaminar la estrella dimensional
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit')
BEGIN
    EXEC('CREATE SCHEMA audit');
END
GO

-- -------------------------------------------------------------------------
-- LIMPIEZA PREVIA IDEMPOTENTE (Respetando el orden inverso de dependencias de FK)
-- -------------------------------------------------------------------------
IF OBJECT_ID('dbo.FACT_VENTAS', 'U') IS NOT NULL DROP TABLE dbo.FACT_VENTAS;
IF OBJECT_ID('dbo.DIM_TIEMPO', 'U') IS NOT NULL DROP TABLE dbo.DIM_TIEMPO;
IF OBJECT_ID('dbo.DIM_CLIENTE', 'U') IS NOT NULL DROP TABLE dbo.DIM_CLIENTE;
IF OBJECT_ID('dbo.DIM_PRODUCTO', 'U') IS NOT NULL DROP TABLE dbo.DIM_PRODUCTO;
IF OBJECT_ID('dbo.DIM_SUCURSAL', 'U') IS NOT NULL DROP TABLE dbo.DIM_SUCURSAL;
IF OBJECT_ID('dbo.DIM_ZONA_ENTREGA', 'U') IS NOT NULL DROP TABLE dbo.DIM_ZONA_ENTREGA;
IF OBJECT_ID('dbo.DIM_REPARTIDOR', 'U') IS NOT NULL DROP TABLE dbo.DIM_REPARTIDOR;
IF OBJECT_ID('dbo.DIM_METODO_PAGO', 'U') IS NOT NULL DROP TABLE dbo.DIM_METODO_PAGO;
IF OBJECT_ID('audit.AUDITORIA_CUADRE_PEDIDOS', 'U') IS NOT NULL DROP TABLE audit.AUDITORIA_CUADRE_PEDIDOS;
GO

-- =========================================================================
-- 1. DIMENSIONES DEL ESQUEMA ESTRELLA
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1.1 DIMENSIÓN TIEMPO (Punto 3 del Decálogo)
-- Grano: Un registro por mes. Origen: orders.placed_at truncado a mes.
-- -------------------------------------------------------------------------
CREATE TABLE dbo.DIM_TIEMPO (
    tiempo_key      INT NOT NULL,              -- Formato AAAAMM (ej. 202601)
    mes             TINYINT NOT NULL,         -- 1 a 12
    nombre_mes      VARCHAR(20) NOT NULL,     -- 'Enero', 'Febrero', etc.
    semestre        TINYINT NOT NULL,         -- 1 o 2
    [año]           SMALLINT NOT NULL,        -- Año calendario (ej. 2026)
    
    CONSTRAINT PK_DIM_TIEMPO PRIMARY KEY CLUSTERED (tiempo_key),
    CONSTRAINT CK_DIM_TIEMPO_mes CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT CK_DIM_TIEMPO_semestre CHECK (semestre IN (1, 2))
);
GO

-- -------------------------------------------------------------------------
-- 1.2 DIMENSIÓN CLIENTE (Punto 4 del Decálogo)
-- Origen: customers. Excluye datos de seguridad (password_hash) y 
-- datos transaccionales volátiles (loyalty_balance, referral_code).
-- -------------------------------------------------------------------------
CREATE TABLE dbo.DIM_CLIENTE (
    cliente_key     INT IDENTITY(1,1) NOT NULL, -- Clave sustituta del DW
    customer_id_nk  INT NOT NULL,              -- Clave natural del TPS (customers.id)
    name            VARCHAR(150) NOT NULL,      -- Nombre del cliente
    phone           VARCHAR(30) NULL,           -- Teléfono
    email           VARCHAR(150) NULL,          -- Correo electrónico
    phone_verified  CHAR(1) NOT NULL,          -- 'S' / 'N'
    email_verified  CHAR(1) NOT NULL,          -- 'S' / 'N'
    es_referido     CHAR(1) NOT NULL,          -- 'S' / 'N' (customers.referred_by IS NOT NULL)
    fecha_registro  DATETIME2(0) NULL,         -- customers.created_at
    
    CONSTRAINT PK_DIM_CLIENTE PRIMARY KEY CLUSTERED (cliente_key),
    CONSTRAINT UQ_DIM_CLIENTE_nk UNIQUE NONCLUSTERED (customer_id_nk),
    CONSTRAINT CK_DIM_CLIENTE_phone_ver CHECK (phone_verified IN ('S', 'N')),
    CONSTRAINT CK_DIM_CLIENTE_email_ver CHECK (email_verified IN ('S', 'N')),
    CONSTRAINT CK_DIM_CLIENTE_referido CHECK (es_referido IN ('S', 'N'))
);
GO

-- -------------------------------------------------------------------------
-- 1.3 DIMENSIÓN PRODUCTO (Punto 5 del Decálogo)
-- Origen: products y categories desnormalizadas (evita modelo copo de nieve).
-- Excluye precios de lista/descuento (el precio real se toma en el hecho).
-- -------------------------------------------------------------------------
CREATE TABLE dbo.DIM_PRODUCTO (
    producto_key         INT IDENTITY(1,1) NOT NULL, -- Clave sustituta del DW
    product_id_nk        INT NOT NULL,              -- Clave natural del TPS (products.id)
    name                 VARCHAR(150) NOT NULL,      -- Nombre del producto
    description          VARCHAR(500) NULL,          -- Descripción del producto
    is_seasonal          CHAR(1) NOT NULL,          -- 'S' / 'N'
    is_available         CHAR(1) NOT NULL,          -- 'S' / 'N'
    category_name        VARCHAR(100) NOT NULL,      -- Nombre de categoría desnormalizada
    category_description VARCHAR(500) NULL,          -- Descripción de la categoría
    
    CONSTRAINT PK_DIM_PRODUCTO PRIMARY KEY CLUSTERED (producto_key),
    CONSTRAINT UQ_DIM_PRODUCTO_nk UNIQUE NONCLUSTERED (product_id_nk),
    CONSTRAINT CK_DIM_PRODUCTO_seasonal CHECK (is_seasonal IN ('S', 'N')),
    CONSTRAINT CK_DIM_PRODUCTO_available CHECK (is_available IN ('S', 'N'))
);
GO

-- -------------------------------------------------------------------------
-- 1.4 DIMENSIÓN SUCURSAL (Punto 6 del Decálogo)
-- Origen: branches. Mesas no es dimensión (se modela como degenerada en hecho).
-- -------------------------------------------------------------------------
CREATE TABLE dbo.DIM_SUCURSAL (
    sucursal_key    INT IDENTITY(1,1) NOT NULL, -- Clave sustituta del DW
    branch_id_nk    INT NOT NULL,              -- Clave natural del TPS (branches.id)
    name            VARCHAR(150) NOT NULL,      -- Nombre de la sucursal (branches.name)
    address         VARCHAR(300) NOT NULL,      -- Dirección física (branches.address)
    phone           VARCHAR(30) NULL,           -- Teléfono (branches.phone)
    latitude        DECIMAL(10,7) NULL,        -- Coordenada latitud
    longitude       DECIMAL(10,7) NULL,        -- Coordenada longitud
    is_active       CHAR(1) NOT NULL,          -- 'S' / 'N'
    
    CONSTRAINT PK_DIM_SUCURSAL PRIMARY KEY CLUSTERED (sucursal_key),
    CONSTRAINT UQ_DIM_SUCURSAL_nk UNIQUE NONCLUSTERED (branch_id_nk),
    CONSTRAINT CK_DIM_SUCURSAL_active CHECK (is_active IN ('S', 'N'))
);
GO

-- -------------------------------------------------------------------------
-- 1.5 DIMENSIÓN ZONA DE ENTREGA (Punto 7 del Decálogo)
-- Origen: delivery_zones vinculada mediante customer_addresses.zone_id.
-- -------------------------------------------------------------------------
CREATE TABLE dbo.DIM_ZONA_ENTREGA (
    zona_key            INT IDENTITY(1,1) NOT NULL, -- Clave sustituta del DW
    zone_id_nk          INT NOT NULL,              -- Clave natural del TPS (delivery_zones.id)
    name                VARCHAR(120) NOT NULL,      -- Nombre de la zona de delivery
    tarifa_base         DECIMAL(12,2) NOT NULL,    -- Tarifa base de envío (delivery_fee)
    min_order_amount    DECIMAL(12,2) NOT NULL,    -- Monto mínimo de pedido
    estimated_minutes   INT NOT NULL,              -- Tiempo estimado de entrega (min)
    is_active           CHAR(1) NOT NULL,          -- 'S' / 'N'
    
    CONSTRAINT PK_DIM_ZONA_ENTREGA PRIMARY KEY CLUSTERED (zona_key),
    CONSTRAINT UQ_DIM_ZONA_ENTREGA_nk UNIQUE NONCLUSTERED (zone_id_nk),
    CONSTRAINT CK_DIM_ZONA_active CHECK (is_active IN ('S', 'N'))
);
GO

-- -------------------------------------------------------------------------
-- 1.6 DIMENSIÓN REPARTIDOR (Punto 8 del Decálogo)
-- Origen: delivery_personnel vinculado por deliveries.delivery_person_id.
-- Excluye availability, telemetría en tiempo real y datos privados (licencia).
-- -------------------------------------------------------------------------
CREATE TABLE dbo.DIM_REPARTIDOR (
    repartidor_key          INT IDENTITY(1,1) NOT NULL, -- Clave sustituta del DW
    delivery_person_id_nk   INT NOT NULL,              -- Clave natural (delivery_personnel.id)
    name                    VARCHAR(150) NOT NULL,      -- Nombre del repartidor
    phone                   VARCHAR(30) NULL,           -- Teléfono de contacto
    vehicle_type            VARCHAR(50) NOT NULL,      -- Tipo de vehículo (Motorcycle, Bicycle, etc.)
    vehicle_number          VARCHAR(50) NULL,           -- Matrícula o identificador del vehículo
    
    CONSTRAINT PK_DIM_REPARTIDOR PRIMARY KEY CLUSTERED (repartidor_key),
    CONSTRAINT UQ_DIM_REPARTIDOR_nk UNIQUE NONCLUSTERED (delivery_person_id_nk)
);
GO

-- -------------------------------------------------------------------------
-- 1.7 DIMENSIÓN MÉTODO DE PAGO (Punto 9 del Decálogo)
-- Origen: Dominio del enumerado payments.method del TPS (no hay tabla maestra).
-- -------------------------------------------------------------------------
CREATE TABLE dbo.DIM_METODO_PAGO (
    metodo_pago_key INT IDENTITY(1,1) NOT NULL, -- Clave sustituta del DW
    codigo_metodo   VARCHAR(50) NOT NULL,      -- Clave natural del enumerado
    nombre_metodo   VARCHAR(100) NOT NULL,     -- Nombre descriptivo en español
    
    CONSTRAINT PK_DIM_METODO_PAGO PRIMARY KEY CLUSTERED (metodo_pago_key),
    CONSTRAINT UQ_DIM_METODO_PAGO_cod UNIQUE NONCLUSTERED (codigo_metodo)
);
GO


-- =========================================================================
-- 2. TABLA DE HECHOS CENTRAL: FACT_VENTAS (Punto 10 del Decálogo)
-- Grano: Una fila por línea de pedido (order_items.id).
-- =========================================================================
CREATE TABLE dbo.FACT_VENTAS (
    venta_key               BIGINT IDENTITY(1,1) NOT NULL, -- Clave sustituta del hecho

    -- Dimensiones Degeneradas Transaccionales (Identificadores del TPS)
    order_item_id           BIGINT NOT NULL,       -- Identificador de línea (grano order_items.id)
    order_id                BIGINT NOT NULL,       -- Identificador del pedido (para COUNT DISTINCT)
    order_number            VARCHAR(50) NOT NULL,  -- Código comercial legible del pedido

    -- Claves Foráneas (Claves Sustitutas hacia Dimensiones) - Todas estrictamente NOT NULL
    tiempo_key              INT NOT NULL,
    cliente_key             INT NOT NULL,
    producto_key            INT NOT NULL,
    sucursal_key            INT NOT NULL,
    zona_key                INT NOT NULL,
    repartidor_key          INT NOT NULL,
    metodo_pago_key         INT NOT NULL,

    -- Atributos Degenerados de Contexto y Banderas
    tipo_pedido             VARCHAR(30) NOT NULL,  -- Canal de venta: 'delivery' (55,0 %) o 'dine_in' (45,0 %)
    estado_pedido           VARCHAR(30) NOT NULL,  -- Estado: 'delivered', 'completed', 'cancelled', etc.
    codigo_cupon            VARCHAR(50) NULL,      -- Código de cupón aplicado a la orden (coupons.code)
    numero_mesa             VARCHAR(20) NULL,      -- Mesa en salón (dining_tables.table_number)
    en_promocion            CHAR(1) NOT NULL,      -- 'S' / 'N' (si aplicó promoción en fecha)

    -- Medidas de Línea y Medidas Prorrateadas de Cabecera
    -- Regla de prorrateo: peso_linea = subtotal_linea / SUM(subtotal_orden)
    quantity                INT NOT NULL,          -- Unidades vendidas (order_items.quantity)
    unit_price              DECIMAL(12,2) NOT NULL,-- Precio unitario de venta (order_items.unit_price)
    descuento_linea         DECIMAL(12,2) NOT NULL,-- Descuento específico de la línea (order_items.discount)
    subtotal                DECIMAL(12,2) NOT NULL,-- Monto de línea después de descuento_linea
    
    descuento_pedido_prorr  DECIMAL(12,4) NOT NULL,-- Descuento general del pedido prorrateado
    descuento_cupon_prorr   DECIMAL(12,4) NOT NULL,-- Descuento por cupón prorrateado
    costo_envio_prorr       DECIMAL(12,4) NOT NULL,-- Costo de delivery prorrateado
    impuesto_prorr          DECIMAL(12,4) NOT NULL,-- Impuesto prorrateado

    -- Medida Neta Auditada:
    -- FÓRMULA CORREGIDA Y VERIFICADA CONTRA EL TPS:
    -- subtotal ya viene neto del descuento_linea en el TPS.
    -- Por lo tanto: monto_neto = subtotal - descuento_cupon_prorr + costo_envio_prorr + impuesto_prorr
    monto_neto              DECIMAL(12,4) NOT NULL,

    -- Medidas de Logística y Satisfacción
    calificacion            TINYINT NULL,          -- Reseña aprobada (1 a 5, NULL si no existe)
    minutos_entrega         INT NULL,              -- deliveries.delivered_at - orders.placed_at
    line_count              TINYINT NOT NULL DEFAULT 1, -- Constante = 1 para conteo aditivo de líneas

    -- Restricciones de Integridad y Dominio
    CONSTRAINT PK_FACT_VENTAS PRIMARY KEY CLUSTERED (venta_key),
    CONSTRAINT UQ_FACT_VENTAS_order_item UNIQUE NONCLUSTERED (order_item_id),
    CONSTRAINT CK_FACT_VENTAS_promocion CHECK (en_promocion IN ('S', 'N')),
    CONSTRAINT CK_FACT_VENTAS_line_count CHECK (line_count = 1),
    CONSTRAINT CK_FACT_VENTAS_calificacion CHECK (calificacion IS NULL OR calificacion BETWEEN 1 AND 5),

    -- Relaciones Estrella Directas (1 a N hacia cada dimensión)
    CONSTRAINT FK_FACT_VENTAS_TIEMPO FOREIGN KEY (tiempo_key) 
        REFERENCES dbo.DIM_TIEMPO (tiempo_key),
    CONSTRAINT FK_FACT_VENTAS_CLIENTE FOREIGN KEY (cliente_key) 
        REFERENCES dbo.DIM_CLIENTE (cliente_key),
    CONSTRAINT FK_FACT_VENTAS_PRODUCTO FOREIGN KEY (producto_key) 
        REFERENCES dbo.DIM_PRODUCTO (producto_key),
    CONSTRAINT FK_FACT_VENTAS_SUCURSAL FOREIGN KEY (sucursal_key) 
        REFERENCES dbo.DIM_SUCURSAL (sucursal_key),
    CONSTRAINT FK_FACT_VENTAS_ZONA FOREIGN KEY (zona_key) 
        REFERENCES dbo.DIM_ZONA_ENTREGA (zona_key),
    CONSTRAINT FK_FACT_VENTAS_REPARTIDOR FOREIGN KEY (repartidor_key) 
        REFERENCES dbo.DIM_REPARTIDOR (repartidor_key),
    CONSTRAINT FK_FACT_VENTAS_METODO_PAGO FOREIGN KEY (metodo_pago_key) 
        REFERENCES dbo.DIM_METODO_PAGO (metodo_pago_key)
);
GO

-- =========================================================================
-- 3. ÍNDICES ANALÍTICOS (Optimización de Filtros, Agrupaciones y Joins BI)
-- =========================================================================
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_tiempo ON dbo.FACT_VENTAS (tiempo_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_producto ON dbo.FACT_VENTAS (producto_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_sucursal ON dbo.FACT_VENTAS (sucursal_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_cliente ON dbo.FACT_VENTAS (cliente_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_zona ON dbo.FACT_VENTAS (zona_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_repartidor ON dbo.FACT_VENTAS (repartidor_key);
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_metodo_pago ON dbo.FACT_VENTAS (metodo_pago_key);

-- Índice compuesto para acelerar conteos de órdenes únicas y tickets medios:
CREATE NONCLUSTERED INDEX IX_FACT_VENTAS_order_id ON dbo.FACT_VENTAS (order_id, tiempo_key, sucursal_key);
GO


-- =========================================================================
-- 4. TABLA TÉCNICA DE CONTROL: AUDITORÍA DE CUADRE ETL
-- Ubicada en el esquema 'audit' para no contaminar el modelo dimensional estrella
-- =========================================================================
CREATE TABLE audit.AUDITORIA_CUADRE_PEDIDOS (
    auditoria_id        BIGINT IDENTITY(1,1) NOT NULL,
    order_id            BIGINT NOT NULL,               -- Pedido evaluado
    order_number        VARCHAR(50) NOT NULL,          -- Código del pedido
    total_amount_tps    DECIMAL(12,4) NOT NULL,        -- Monto total registrado en orders.total_amount
    suma_monto_neto_dw  DECIMAL(12,4) NOT NULL,        -- SUM(monto_neto) de las líneas en FACT_VENTAS
    diferencia          DECIMAL(12,4) NOT NULL,        -- total_amount_tps - suma_monto_neto_dw
    fecha_auditoria     DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    
    CONSTRAINT PK_AUDITORIA_CUADRE PRIMARY KEY CLUSTERED (auditoria_id)
);
GO


-- =========================================================================
-- 5. POBLAMIENTO INICIAL DE REGLAS DE NEGOCIO DEL DECÁLOGO
--    a) Miembros comodín / por defecto con clave -1
--    b) Carga de catálogo de métodos de pago desde el enumerado del TPS
--    c) Calendario mensual continuo en DIM_TIEMPO
-- =========================================================================

-- 5.1 Miembro Comodín (-1) en DIM_CLIENTE: "Cliente invitado" (Punto 4)
SET IDENTITY_INSERT dbo.DIM_CLIENTE ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DIM_CLIENTE WHERE cliente_key = -1)
BEGIN
    INSERT INTO dbo.DIM_CLIENTE (cliente_key, customer_id_nk, name, phone, email, phone_verified, email_verified, es_referido, fecha_registro)
    VALUES (-1, -1, 'Cliente invitado', 'N/A', 'invitado@restaurant.com', 'N', 'N', 'N', NULL);
    PRINT 'Miembro comodín -1 insertado en DIM_CLIENTE.';
END
SET IDENTITY_INSERT dbo.DIM_CLIENTE OFF;
GO

-- 5.2 Miembro Comodín (-1) en DIM_ZONA_ENTREGA: "No aplica" (Punto 7: Consumo en Local)
SET IDENTITY_INSERT dbo.DIM_ZONA_ENTREGA ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DIM_ZONA_ENTREGA WHERE zona_key = -1)
BEGIN
    INSERT INTO dbo.DIM_ZONA_ENTREGA (zona_key, zone_id_nk, name, tarifa_base, min_order_amount, estimated_minutes, is_active)
    VALUES (-1, -1, 'No aplica (Consumo en Local)', 0.00, 0.00, 0, 'N');
    PRINT 'Miembro comodín -1 insertado en DIM_ZONA_ENTREGA.';
END
SET IDENTITY_INSERT dbo.DIM_ZONA_ENTREGA OFF;
GO

-- 5.3 Miembro Comodín (-1) en DIM_REPARTIDOR: "No aplica" (Punto 8: Consumo en Local)
SET IDENTITY_INSERT dbo.DIM_REPARTIDOR ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DIM_REPARTIDOR WHERE repartidor_key = -1)
BEGIN
    INSERT INTO dbo.DIM_REPARTIDOR (repartidor_key, delivery_person_id_nk, name, phone, vehicle_type, vehicle_number)
    VALUES (-1, -1, 'No aplica (Consumo en Local)', 'N/A', 'N/A', 'N/A');
    PRINT 'Miembro comodín -1 insertado en DIM_REPARTIDOR.';
END
SET IDENTITY_INSERT dbo.DIM_REPARTIDOR OFF;
GO

-- 5.4 Miembro Comodín (-1) en DIM_METODO_PAGO: "Sin pago" (Punto 9: Pedidos sin pago exitoso)
SET IDENTITY_INSERT dbo.DIM_METODO_PAGO ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DIM_METODO_PAGO WHERE metodo_pago_key = -1)
BEGIN
    INSERT INTO dbo.DIM_METODO_PAGO (metodo_pago_key, codigo_metodo, nombre_metodo)
    VALUES (-1, 'SIN_PAGO', 'Sin pago exitoso');
    PRINT 'Miembro comodín -1 insertado en DIM_METODO_PAGO.';
END
SET IDENTITY_INSERT dbo.DIM_METODO_PAGO OFF;
GO

-- 5.5 Carga fija del enumerado de Métodos de Pago del TPS (Punto 9)
IF NOT EXISTS (SELECT 1 FROM dbo.DIM_METODO_PAGO WHERE codigo_metodo = 'cash')
BEGIN
    INSERT INTO dbo.DIM_METODO_PAGO (codigo_metodo, nombre_metodo)
    VALUES 
        ('cash',    'Efectivo'),
        ('card',    'Tarjeta de Débito / Crédito'),
        ('bkash',   'Billetera Móvil bKash'),
        ('nagad',   'Billetera Móvil Nagad'),
        ('rocket',  'Billetera Móvil Rocket'),
        ('gateway', 'Pasarela de Pago Online');
    PRINT 'Catálogo de métodos de pago cargado en DIM_METODO_PAGO.';
END
GO

-- 5.6 Población del Calendario Continuo Mensual (DIM_TIEMPO) para los años 2025 y 2026
;WITH RangoMeses AS (
    SELECT CAST('2025-01-01' AS DATE) AS FechaMes
    UNION ALL
    SELECT DATEADD(MONTH, 1, FechaMes)
    FROM RangoMeses
    WHERE FechaMes < '2026-12-01'
)
INSERT INTO dbo.DIM_TIEMPO (tiempo_key, mes, nombre_mes, semestre, [año])
SELECT
    (YEAR(FechaMes) * 100) + MONTH(FechaMes) AS tiempo_key,
    CAST(MONTH(FechaMes) AS TINYINT) AS mes,
    CASE MONTH(FechaMes)
        WHEN 1  THEN 'Enero'
        WHEN 2  THEN 'Febrero'
        WHEN 3  THEN 'Marzo'
        WHEN 4  THEN 'Abril'
        WHEN 5  THEN 'Mayo'
        WHEN 6  THEN 'Junio'
        WHEN 7  THEN 'Julio'
        WHEN 8  THEN 'Agosto'
        WHEN 9  THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END AS nombre_mes,
    CASE WHEN MONTH(FechaMes) <= 6 THEN 1 ELSE 2 END AS semestre,
    CAST(YEAR(FechaMes) AS SMALLINT) AS [año]
FROM RangoMeses
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.DIM_TIEMPO WHERE tiempo_key = (YEAR(FechaMes) * 100) + MONTH(FechaMes)
);
GO

PRINT '=========================================================================';
PRINT 'ESTRUCTURA DEL DATA WAREHOUSE JUICECORNER_DW CREADA Y POBLADA CON ÉXITO.';
PRINT '=========================================================================';
GO
