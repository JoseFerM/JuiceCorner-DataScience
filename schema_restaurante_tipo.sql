-- ============================================================================
-- ESTRUCTURA TIPO: BASE DE DATOS RESTAURANTE & DELIVERY
-- Compatible con MySQL / MariaDB (Laragon) y PostgreSQL (con mínimas adaptaciones)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS restaurante_delivery CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE restaurante_delivery;

-- 1. SUCURSALES (Branches)
CREATE TABLE IF NOT EXISTS sucursales (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    telefono VARCHAR(30),
    latitud DECIMAL(10, 7),
    longitud DECIMAL(10, 7),
    activo BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. CATEGORÍAS (Menu Categories)
CREATE TABLE IF NOT EXISTS categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- 3. PRODUCTOS (Products / Menu Items)
CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id INT NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL,
    precio_descuento DECIMAL(10, 2) DEFAULT NULL,
    disponible BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id) 
        REFERENCES categorias(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 4. CLIENTES (Customers)
CREATE TABLE IF NOT EXISTS clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    telefono VARCHAR(30) NOT NULL,
    puntos_lealtad INT DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 5. DIRECCIONES DE CLIENTE (Addresses)
CREATE TABLE IF NOT EXISTS direcciones_cliente (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    etiqueta VARCHAR(50) DEFAULT 'Casa', -- 'Casa', 'Trabajo', 'Otro'
    direccion VARCHAR(255) NOT NULL,
    referencia VARCHAR(255),
    latitud DECIMAL(10, 7),
    longitud DECIMAL(10, 7),
    es_predeterminada BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_direccion_cliente FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 6. REPARTIDORES (Delivery Personnel)
CREATE TABLE IF NOT EXISTS repartidores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(30) NOT NULL UNIQUE,
    vehiculo_tipo ENUM('moto', 'bicicleta', 'auto') DEFAULT 'moto',
    estado ENUM('disponible', 'ocupado', 'desconectado') DEFAULT 'desconectado',
    activo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- 7. PEDIDOS (Orders)
CREATE TABLE IF NOT EXISTS pedidos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_pedido VARCHAR(30) NOT NULL UNIQUE,
    cliente_id INT NOT NULL,
    sucursal_id INT NOT NULL,
    direccion_id INT NULL, -- NULL si es para consumo en local (dine-in)
    tipo ENUM('delivery', 'para_llevar', 'salon') NOT NULL DEFAULT 'delivery',
    estado ENUM('pendiente', 'confirmado', 'en_cocina', 'listo', 'en_camino', 'entregado', 'cancelado') DEFAULT 'pendiente',
    subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    costo_envio DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    descuento DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    notas TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_sucursal FOREIGN KEY (sucursal_id) 
        REFERENCES sucursales(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_direccion FOREIGN KEY (direccion_id) 
        REFERENCES direcciones_cliente(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 8. DETALLE DE PEDIDOS (Order Items)
CREATE TABLE IF NOT EXISTS pedido_detalles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    instrucciones_especiales VARCHAR(255),
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (pedido_id) 
        REFERENCES pedidos(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (producto_id) 
        REFERENCES productos(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 9. PAGOS (Payments)
CREATE TABLE IF NOT EXISTS pagos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    metodo ENUM('efectivo', 'tarjeta_debito', 'tarjeta_credito', 'transferencia', 'billetera_digital') NOT NULL,
    estado ENUM('pendiente', 'completado', 'fallido', 'reembolsado') DEFAULT 'pendiente',
    monto DECIMAL(10, 2) NOT NULL,
    transaccion_ref VARCHAR(100),
    pagado_en TIMESTAMP NULL,
    CONSTRAINT fk_pago_pedido FOREIGN KEY (pedido_id) 
        REFERENCES pedidos(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 10. ENTREGAS / ENVÍOS (Deliveries)
CREATE TABLE IF NOT EXISTS entregas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL UNIQUE,
    repartidor_id INT NOT NULL,
    estado ENUM('asignado', 'recogido', 'en_camino', 'entregado', 'fallido') DEFAULT 'asignado',
    asignado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    entregado_en TIMESTAMP NULL,
    tiempo_estimado_minutos INT,
    CONSTRAINT fk_entrega_pedido FOREIGN KEY (pedido_id) 
        REFERENCES pedidos(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_entrega_repartidor FOREIGN KEY (repartidor_id) 
        REFERENCES repartidores(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 11. RESEÑAS / CALIFICACIONES (Reviews)
CREATE TABLE IF NOT EXISTS resenas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL UNIQUE,
    cliente_id INT NOT NULL,
    calificacion_comida TINYINT NOT NULL CHECK (calificacion_comida BETWEEN 1 AND 5),
    calificacion_entrega TINYINT CHECK (calificacion_entrega BETWEEN 1 AND 5),
    comentario TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_resena_pedido FOREIGN KEY (pedido_id) 
        REFERENCES pedidos(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_resena_cliente FOREIGN KEY (cliente_id) 
        REFERENCES clientes(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ÍNDICES RECOMENDADOS PARA RENDIMIENTO
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(creado_en);
CREATE INDEX idx_detalles_pedido ON pedido_detalles(pedido_id);
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
