# DECÁLOGO CONSTRUCTIVO, FUNCIONAL Y TÉCNICO (VERSIÓN 2.0 AUDITADA)
## Data Warehouse – Sistema TPS de Pedidos de Restaurante (Juice Corner BD)
### Modelo Dimensional Tipo Estrella · Una Única Tabla de Hechos

---

## Alcance del Diseño

El Data Warehouse se orienta al análisis histórico y gerencial de los pedidos de la cadena de restaurantes **Juice Corner BD**, la cual opera formalmente bajo **dos canales exclusivos de atención comercial** registrados en el sistema transaccional (TPS / OLTP):
1. **Consumo en Local (`dine_in`)**: Representa el **44,97 %** del volumen total (449.736 pedidos). Requiere asignación de mesa física (`dining_tables`), no genera costo de envío y no utiliza repartidor (`zona_key = -1`, `repartidor_key = -1`).
2. **Entrega a Domicilio (`delivery`)**: Representa el **55,03 %** del volumen total (550.264 pedidos). Requiere dirección de entrega (`customer_addresses`), zona logística tarifada (`DIM_ZONA_ENTREGA`) y asignación de repartidor (`DIM_REPARTIDOR`).

> [!NOTE]
> **Aclaración sobre Modalidad Para Llevar (*Takeaway*):**
> En los datos reales del TPS (`orders.csv`), el 100 % de los pedidos se distribuye únicamente entre `delivery` y `dine_in`. No existen pedidos registrados bajo *takeaway* (0 registros). En consecuencia, el modelo analítico y las reglas de negocio se definen formalmente sobre este modelo bipolar de 2 canales.

Se utiliza una arquitectura de **esquema en estrella pura** centrada en una única tabla de hechos, [`dbo.FACT_VENTAS`](file:///C:/Users/Agents/Documents/3.1proyecto/JuiceCorner_DW.sql#L190-L265), vinculada directamente a siete dimensiones conformadas: Tiempo, Cliente, Producto, Sucursal, Zona de Entrega, Repartidor y Método de Pago.

> [!IMPORTANT]
> **Criterio Técnico Clave de Granularidad y Prorrateo:**
> * El grano atómico de `FACT_VENTAS` es **una fila por línea de pedido (`order_items.id`)**.
> * Los atributos de la cabecera del pedido (`orders`) se replican como dimensiones degeneradas en cada una de sus líneas.
> * Los importes que existen a nivel global del pedido (descuento de cupón, costo de envío e impuesto) se prorratean de manera exacta entre sus líneas utilizando como factor el **peso relativo del subtotal** de la línea.
> * El conteo de órdenes en reportes analíticos se obtiene exclusivamente con `COUNT(DISTINCT order_id)` y **nunca** sumando filas.

---

## 1. REQUERIMIENTO DEL SISTEMA ANALÍTICO

1. **Propósito Gerencial:** Construir un Data Warehouse analítico para evaluar ventas brutas y netas, unidades vendidas, descuentos, costos de envío, tiempos de entrega y niveles de satisfacción del cliente, con capacidad de agregación por producto, categoría, sucursal, zona geográfica y período temporal.
2. **Dimensiones Requeridas:** Crear las dimensiones Tiempo, Cliente, Producto, Sucursal, Zona de Entrega, Repartidor y Método de Pago.
3. **Tabla de Hechos Central:** Crear una única tabla de hechos `FACT_VENTAS` con grano atómico de una fila por línea de pedido (`order_items`).
4. **Claves Sustitutas:** Relacionar la tabla de hechos con todas las dimensiones mediante claves sustitutas enteras generadas en el DW (`*_key`), garantizando la independencia frente a reestructuraciones operativas.
5. **Dimensiones Degeneradas:** Conservar `order_item_id`, `order_id` y `order_number` dentro de la tabla de hechos como identificadores transaccionales para trazabilidad y cálculos de agregación a nivel de orden.
6. **Trazabilidad ETL y Claves Naturales:** Conservar en cada dimensión la clave natural del sistema fuente (`*_nk`) para indexación y búsquedas rápidas durante las cargas incrementales del proceso ETL.
7. **Capacidad de Análisis:** Permitir el análisis multidimensional de ventas brutas, ventas netas, descuentos de línea, impacto de cupones, promociones activas, gastos logísticos de envío, tiempos de respuesta de delivery y calificaciones de satisfacción.
8. **Análisis Temporal Continuo:** Mantener información histórica organizada para análisis mensual, semestral y anual continuo, asegurando la visibilidad de períodos con o sin operaciones comerciales.

---

## 2. MODELADO DIMENSIONAL EN ESTRELLA

El modelo sigue un **esquema estrella puro**. La tabla `FACT_VENTAS` se ubica en el centro y las siete dimensiones se relacionan directamente con ella con cardinalidad $1:N$. 

Para preservar la pureza de la estrella y evitar un esquema copo de nieve (*snowflake*), la jerarquía de categorías se desnormaliza directamente dentro de la dimensión Producto.

| Elemento | Tipo de Tabla | Función Analítica en el Negocio |
| :--- | :--- | :--- |
| **`FACT_VENTAS`** | Hechos Central | Hechos transaccionales, importes monetarios, medidas logísticas y de satisfacción a nivel de línea. |
| **`DIM_TIEMPO`** | Dimensión | Jerarquía temporal para análisis mensual, semestral y anual continuo. |
| **`DIM_CLIENTE`** | Dimensión | Perfil del cliente, estado de verificación de contacto y canal de adquisición (referidos). |
| **`DIM_PRODUCTO`** | Dimensión | Catálogo de productos, categorías asociadas y condición estacional/disponibilidad. |
| **`DIM_SUCURSAL`** | Dimensión | Sucursal física responsable de la orden y su localización geoespacial. |
| **`DIM_ZONA_ENTREGA`** | Dimensión | Zonas de cobertura de delivery, tarifas base, montos mínimos y tiempos promedio estimados. |
| **`DIM_REPARTIDOR`** | Dimensión | Personal de reparto y tipología de vehículo asignado. |
| **`DIM_METODO_PAGO`** | Dimensión | Medio de pago utilizado para liquidar la orden. |
| **`audit.AUDITORIA_CUADRE_PEDIDOS`** | Control ETL (Ext. al DW) | Tabla de auditoría técnica que valida la cuadratura contable entre el TPS y el DW. |

---

## 3. DIMENSIÓN TIEMPO – `DIM_TIEMPO`

* **Origen Principal:** Atributo `orders.placed_at`, truncado a nivel de mes.
* **Grano:** Un registro por mes.

| Campo | Tipo de Dato | Descripción | Origen / Regla |
| :--- | :--- | :--- | :--- |
| `tiempo_key` | `INT` (PK) | Clave sustituta con formato numérico `AAAAMM` (ej. 202601). | DW (Clave inteligente) |
| `mes` | `TINYINT` | Número del mes calendario (1–12). | `MONTH(placed_at)` |
| `nombre_mes` | `VARCHAR(20)` | Nombre completo del mes en español (Enero, Febrero...). | Derivado del mes |
| `semestre` | `TINYINT` | Número de semestre del año (1 o 2). | `CASE WHEN mes <= 6 THEN 1 ELSE 2 END` |
| `año` | `SMALLINT` | Año calendario de cuatro dígitos (ej. 2026). | `YEAR(placed_at)` |

> [!NOTE]
> **Generación Continua:** La dimensión se precarga con todos los meses consecutivos del rango de operación (años 2025 y 2026 completos), de modo que los tableros analíticos reflejen con precisión los períodos sin actividad comercial.

---

## 4. DIMENSIÓN CLIENTE – `DIM_CLIENTE`

* **Origen:** Tabla maestra `customers` del TPS.

| Campo | Tipo de Dato | Descripción | Origen / Regla |
| :--- | :--- | :--- | :--- |
| `cliente_key` | `INT` (PK) | Clave sustituta autoincremental del Data Warehouse. | DW |
| `customer_id_nk` | `INT` (UQ) | Clave natural del sistema fuente. | `customers.id` |
| `name` | `VARCHAR(150)` | Nombre completo o razón social del cliente. | `customers.name` |
| `phone` | `VARCHAR(30)` | Teléfono principal de contacto. | `customers.phone` |
| `email` | `VARCHAR(150)` | Correo electrónico registrado. | `customers.email` |
| `phone_verified` | `CHAR(1)` | Indicador de teléfono verificado (`'S'` / `'N'`). | `customers.phone_verified` |
| `email_verified` | `CHAR(1)` | Indicador de correo verificado (`'S'` / `'N'`). | `customers.email_verified` |
| `es_referido` | `CHAR(1)` | Indicador de adquisición por referido (`'S'` / `'N'`). | `customers.referred_by IS NOT NULL` |
| `fecha_registro` | `DATETIME2(0)` | Fecha y hora original de registro en el sistema. | `customers.created_at` |

> [!IMPORTANT]
> **Exclusiones de Seguridad y Estabilidad:**
> * `password_hash` se excluye por estrictas políticas de confidencialidad y gobernanza de datos.
> * `loyalty_balance` y `referral_code` se excluyen de la dimensión por ser valores transaccionales volátiles que cambian en cada transacción.
> * **Miembro Comodín Obligatorio:** Los pedidos realizados por clientes anónimos o no autenticados en el TPS se asignan al registro predeterminado `cliente_key = -1` (*"Cliente invitado"*).

---

## 5. DIMENSIÓN PRODUCTO – `DIM_PRODUCTO`

* **Origen:** Tablas `products` y `categories` desnormalizadas.

| Campo | Tipo de Dato | Descripción | Origen / Regla |
| :--- | :--- | :--- | :--- |
| `producto_key` | `INT` (PK) | Clave sustituta autoincremental del Data Warehouse. | DW |
| `product_id_nk` | `INT` (UQ) | Clave natural del sistema fuente. | `products.id` |
| `name` | `VARCHAR(150)` | Nombre comercial del producto en carta. | `products.name` |
| `description` | `VARCHAR(500)` | Descripción detallada de los ingredientes/receta. | `products.description` |
| `is_seasonal` | `CHAR(1)` | Producto de edición de temporada (`'S'` / `'N'`). | `products.is_seasonal` |
| `is_available` | `CHAR(1)` | Estado de disponibilidad actual en carta (`'S'` / `'N'`). | `products.is_available` |
| `category_name` | `VARCHAR(100)` | Nombre de la categoría desnormalizada. | `categories.name` |
| `category_description`| `VARCHAR(500)` | Descripción de la categoría desnormalizada. | `categories.description` |

> [!NOTE]
> **Exclusión de Medidas de Precio:** Los atributos `price` y `discounted_price` de la tabla maestra de productos se excluyen de la dimensión porque son medidas variables en el tiempo. El precio unitario histórico cobrado se preserva directamente en el hecho (`FACT_VENTAS.unit_price`).

---

## 6. DIMENSIÓN SUCURSAL – `DIM_SUCURSAL`

* **Origen:** Tabla maestra `branches`.

| Campo | Tipo de Dato | Descripción | Origen / Regla |
| :--- | :--- | :--- | :--- |
| `sucursal_key` | `INT` (PK) | Clave sustituta autoincremental del Data Warehouse. | DW |
| `branch_id_nk` | `INT` (UQ) | Clave natural de la sucursal en el TPS. | `branches.id` |
| `name` | `VARCHAR(150)` | Nombre comercial de la sucursal física. | `branches.name` |
| `address` | `VARCHAR(300)` | Dirección física de ubicación. | `branches.address` |
| `phone` | `VARCHAR(30)` | Teléfono de atención de la sede. | `branches.phone` |
| `latitude` | `DECIMAL(10,7)`| Coordenada geográfica de latitud. | `branches.latitude` |
| `longitude` | `DECIMAL(10,7)`| Coordenada geográfica de longitud. | `branches.longitude` |
| `is_active` | `CHAR(1)` | Estado operativo de la sucursal (`'S'` / `'N'`). | `branches.is_active` |

> [!NOTE]
> **Mesas como Dimensión Degenerada:** La entidad `dining_tables` no se modela como una dimensión externa; el número de mesa se almacena directamente en la tabla de hechos (`numero_mesa`) como dimensión degenerada para pedidos en salón.

---

## 7. DIMENSIÓN ZONA DE ENTREGA – `DIM_ZONA_ENTREGA`

* **Origen:** Tabla `delivery_zones`, vinculada al pedido mediante la dirección de entrega: `orders.address_id` $\rightarrow$ `customer_addresses.zone_id`.

| Campo | Tipo de Dato | Descripción | Origen / Regla |
| :--- | :--- | :--- | :--- |
| `zona_key` | `INT` (PK) | Clave sustituta autoincremental del Data Warehouse. | DW |
| `zone_id_nk` | `INT` (UQ) | Clave natural de la zona de delivery. | `delivery_zones.id` |
| `name` | `VARCHAR(120)` | Nombre o denominación de la zona de cobertura. | `delivery_zones.name` |
| `tarifa_base` | `DECIMAL(12,2)`| Tarifa base estipulada para el despacho a la zona. | `delivery_zones.delivery_fee` |
| `min_order_amount` | `DECIMAL(12,2)`| Monto mínimo requerido para autorizar delivery. | `delivery_zones.min_order_amount` |
| `estimated_minutes`| `INT` | Tiempo de viaje estimado en minutos hacia la zona. | `delivery_zones.estimated_minutes` |
| `is_active` | `CHAR(1)` | Estado de habilitación de la zona (`'S'` / `'N'`). | `delivery_zones.is_active` |

> [!IMPORTANT]
> **Miembro Comodín Obligatorio:** Los pedidos bajo el canal de consumo en local (`dine_in`) se atienden en mesa física y carecen de zona de entrega; en estos casos se asigna obligatoriamente el miembro comodín `zona_key = -1` (*"No aplica (Consumo en Local)"*). La columna en `FACT_VENTAS` es `NOT NULL`.

---

## 8. DIMENSIÓN REPARTIDOR – `DIM_REPARTIDOR`

* **Origen:** Tabla `delivery_personnel`, vinculada mediante la entrega: `deliveries.delivery_person_id`.

| Campo | Tipo de Dato | Descripción | Origen / Regla |
| :--- | :--- | :--- | :--- |
| `repartidor_key` | `INT` (PK) | Clave sustituta autoincremental del Data Warehouse. | DW |
| `delivery_person_id_nk` | `INT` (UQ) | Clave natural del repartidor en el TPS. | `delivery_personnel.id` |
| `name` | `VARCHAR(150)` | Nombre completo del repartidor. | `delivery_personnel.name` |
| `phone` | `VARCHAR(30)` | Teléfono de contacto operativo. | `delivery_personnel.phone` |
| `vehicle_type` | `VARCHAR(50)` | Categoría del vehículo empleado (moto, auto, bici). | `delivery_personnel.vehicle_type` |
| `vehicle_number`| `VARCHAR(50)` | Identificador o matrícula del vehículo. | `delivery_personnel.vehicle_number` |

> [!IMPORTANT]
> **Exclusiones de Telemetría Operativa:** Los campos `availability`, `current_latitude` y `current_longitude` son datos operacionales en tiempo real sin propósito histórico, por lo que no se cargan. `license_number` se excluye por privacidad.
> **Miembro Comodín Obligatorio:** Todos los pedidos del canal local (`dine_in`) no utilizan servicio logístico de entrega y se asignan obligatoriamente al miembro comodín `repartidor_key = -1` (*"No aplica (Consumo en Local)"*).

---

## 9. DIMENSIÓN MÉTODO DE PAGO – `DIM_METODO_PAGO`

* **Origen:** Dominio del enumerado `payments.method` del TPS (el sistema fuente no posee una tabla maestra de medios de pago).

| Campo | Tipo de Dato | Descripción | Origen / Regla |
| :--- | :--- | :--- | :--- |
| `metodo_pago_key` | `INT` (PK) | Clave sustituta autoincremental del Data Warehouse. | DW |
| `codigo_metodo` | `VARCHAR(50)` | Clave natural / código del enumerado transaccional. | `payments.method` |
| `nombre_metodo` | `VARCHAR(100)` | Nombre descriptivo en lenguaje natural de negocio. | Derivado del código |

> [!IMPORTANT]
> **Carga Única y Pedidos sin Pago:**
> * La dimensión se precarga una única vez con los valores del enumerado (`cash`, `card`, `bkash`, `nagad`, `rocket`, `gateway`).
> * En caso de órdenes canceladas o pendientes de liquidación financiera, se asigna el miembro comodín `metodo_pago_key = -1` (*"Sin pago exitoso"*).

---

## 10. TABLA DE HECHOS CENTRAL – `FACT_VENTAS`

* **Grano del Hecho:** Una única fila por cada línea de pedido registrada (`order_items.id`).
* **Integridad Referencial:** Todas las claves foráneas hacia las dimensiones están configuradas como **`NOT NULL`** hacia claves válidas o registros comodín (`-1`).

| Campo | Tipo de Dato | Rol Dimensional | Origen / Regla de Cálculo |
| :--- | :--- | :--- | :--- |
| `venta_key` | `BIGINT` (PK) | Clave primaria sustituta | Autoincremental en el Data Warehouse. |
| `order_item_id` | `BIGINT` (UQ) | Dimensión Degenerada | `order_items.id` (garantía del grano atómico). |
| `order_id` | `BIGINT` | Dimensión Degenerada | `orders.id` (requerido para `COUNT(DISTINCT order_id)`). |
| `order_number` | `VARCHAR(50)` | Dimensión Degenerada | `orders.order_number` (identificador comercial). |
| `tiempo_key` | `INT` (FK) | Clave Foránea | `AAAAMM` correspondiente a `orders.placed_at`. |
| `cliente_key` | `INT` (FK) | Clave Foránea | Vínculo a `DIM_CLIENTE` (`-1` si es anónimo). |
| `producto_key` | `INT` (FK) | Clave Foránea | Vínculo a `DIM_PRODUCTO` (`order_items.product_id`). |
| `sucursal_key` | `INT` (FK) | Clave Foránea | Vínculo a `DIM_SUCURSAL` (`orders.branch_id`). |
| `zona_key` | `INT` (FK) | Clave Foránea | Vínculo a `DIM_ZONA_ENTREGA` (`-1` si no aplica). |
| `repartidor_key`| `INT` (FK) | Clave Foránea | Vínculo a `DIM_REPARTIDOR` (`-1` si no aplica). |
| `metodo_pago_key`| `INT` (FK) | Clave Foránea | Vínculo a `DIM_METODO_PAGO` (`-1` si no aplica). |
| `tipo_pedido` | `VARCHAR(30)` | Atributo Degenerado | Canal de venta: `dine_in` (Consumo en Local, 44,97 %) o `delivery` (Entrega a Domicilio, 55,03 %). |
| `estado_pedido`| `VARCHAR(30)` | Atributo Degenerado | Estado del pedido: `entregado`, `cancelado`, etc. |
| `codigo_cupon` | `VARCHAR(50)` | Atributo Degenerado | Código del cupón aplicado en la orden (o `NULL`). |
| `numero_mesa` | `VARCHAR(20)` | Atributo Degenerado | Mesa asignada en salón (o `NULL`). |
| `en_promocion` | `CHAR(1)` | Indicador Degenerado | `'S'` si el producto tenía promoción activa en la fecha. |
| `quantity` | `INT` | Medida Aditiva | Cantidad física de unidades vendidas en la línea. |
| `unit_price` | `DECIMAL(12,2)`| Medida No Aditiva | Precio unitario histórico pactado en la venta. |
| `descuento_linea`| `DECIMAL(12,2)`| Medida Aditiva | Descuento directo aplicado sobre la línea. |
| `subtotal` | `DECIMAL(12,2)`| Medida Aditiva | Monto bruto de la línea después de `descuento_linea`. |
| `descuento_pedido_prorr`| `DECIMAL(12,4)`| Medida Prorrateada | Descuento global prorrateado por peso de línea. |
| `descuento_cupon_prorr` | `DECIMAL(12,4)`| Medida Prorrateada | Descuento de cupón prorrateado por peso de línea. |
| `costo_envio_prorr` | `DECIMAL(12,4)`| Medida Prorrateada | Tarifa de delivery prorrateada por peso de línea. |
| `impuesto_prorr` | `DECIMAL(12,4)`| Medida Prorrateada | Carga impositiva prorrateada por peso de línea. |
| `monto_neto` | `DECIMAL(12,4)`| Medida Aditiva | **Importe neto auditado** correspondiente a la línea. |
| `calificacion` | `TINYINT` | Medida Semi-Aditiva | Puntuación de reseña aprobada (1 a 5, o `NULL`). |
| `minutos_entrega`| `INT` | Medida Semi-Aditiva | Minutos transcurridos desde pedido hasta entrega. |
| `line_count` | `TINYINT` | Medida Aditiva | Constante `= 1` para conteo directo de registros. |

### Regla Técnica de Prorrateo de Importes de Cabecera
Dado que el grano del Data Warehouse es la línea de pedido, los importes definidos a nivel de cabecera (`orders`) se distribuyen entre sus líneas utilizando el factor de peso:
$$\text{peso\_linea} = \frac{\text{order\_items.subtotal}}{\sum \text{order\_items.subtotal del pedido}}$$

Con este factor se calculan de forma exacta:
* $\text{descuento\_pedido\_prorr} = \text{orders.discount\_amount} \times \text{peso\_linea}$
* $\text{descuento\_cupon\_prorr} = \text{orders.coupon\_discount} \times \text{peso\_linea}$
* $\text{costo\_envio\_prorr} = \text{orders.delivery\_fee} \times \text{peso\_linea}$
* $\text{impuesto\_prorr} = \text{orders.tax} \times \text{peso\_linea}$

### Justificación de la Fórmula de `monto_neto`
> [!CAUTION]
> **Evitar el Defecto de Doble Descuento:**
> En la base de datos transaccional, el campo `order_items.subtotal` ya viene deducido del descuento directo de la línea (`order_items.discount`). Si en la fórmula del monto neto se volviese a restar el descuento prorrateado de cabecera, dicho importe se descontaría dos veces.
> Por lo tanto, la fórmula exacta que garantiza la cuadratura contable contra el TPS es:
> $$\mathbf{monto\_neto} = \mathbf{subtotal} - \mathbf{descuento\_cupon\_prorr} + \mathbf{costo\_envio\_prorr} + \mathbf{impuesto\_prorr}$$

### Reglas de Explotación Analítica en Consultas y Reportes
1. **Conteo de Órdenes:** Se debe utilizar siempre `COUNT(DISTINCT order_id)` y nunca `COUNT(*)`, ya que un pedido de múltiples productos contiene múltiples filas.
2. **Tiempo de Entrega:** `minutos_entrega` es un atributo de orden replicado en cada línea. Para obtener el tiempo promedio de entrega en un período o zona, se debe calcular el promedio considerando órdenes distintas (evitando que órdenes grandes sesguen el promedio).
3. **Calificaciones de Satisfacción:** `calificacion` se evalúa mediante `AVG(calificacion)`; SQL Server ignora automáticamente los valores nulos de líneas sin reseña.

---

## ANEXO TÉCNICO I: TABLA DE CONTROL Y AUDITORÍA ETL

La tabla de auditoría se aloja en el esquema técnico `audit` para no contaminar el modelo dimensional:

```sql
CREATE TABLE audit.AUDITORIA_CUADRE_PEDIDOS (
    auditoria_id        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    order_id            BIGINT NOT NULL,
    order_number        VARCHAR(50) NOT NULL,
    total_amount_tps    DECIMAL(12,4) NOT NULL,
    suma_monto_neto_dw  DECIMAL(12,4) NOT NULL,
    diferencia          DECIMAL(12,4) NOT NULL,
    fecha_auditoria     DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
```

Durante el cierre de carga del ETL, se inserta una fila de advertencia si la diferencia absoluta $|\text{total\_amount\_tps} - \text{suma\_monto\_neto\_dw}| > 0.01$.

---

## ANEXO TÉCNICO II: MATRIZ DE TRAZABILIDAD TPS $\rightarrow$ DW

| Entidad / Tabla TPS | Tipo Transaccional | Destino en el Data Warehouse |
| :--- | :--- | :--- |
| `orders` | Cabecera transaccional | Claves foráneas, atributos degenerados y medidas prorrateadas en `FACT_VENTAS`. |
| `order_items` | Detalle transaccional | Grano base, cantidades, precios y subtotales en `FACT_VENTAS`. |
| `customers` | Maestro | Atributos de cliente en `DIM_CLIENTE`. |
| `products` | Maestro | Nombre y especificaciones en `DIM_PRODUCTO`. |
| `categories` | Catálogo maestro | Desnormalizado en `DIM_PRODUCTO.category_name`. |
| `branches` | Maestro | Ubicación y sede en `DIM_SUCURSAL`. |
| `delivery_zones` | Maestro | Cobertura y tarifas en `DIM_ZONA_ENTREGA`. |
| `delivery_personnel` | Maestro | Datos de repartidor en `DIM_REPARTIDOR`. |
| `payments` (enum) | Catálogo implícito | Dominio de medios de pago en `DIM_METODO_PAGO`. |
| `reviews` | Evento relacionado | Puntuación de producto en `FACT_VENTAS.calificacion`. |
| `deliveries` | Transacción logística | Tiempos de entrega en `FACT_VENTAS.minutos_entrega`. |

---

## ANEXO TÉCNICO III: NOTA DE ALCANCE RESPECTO AL MARGEN DE CONTRIBUCIÓN

El presente Decálogo delimita y formaliza la arquitectura del subsistema transaccional de **ventas, pedidos y despachos** de Juice Corner BD. 

Dado que el objetivo SMART principal de las siguientes fases del proyecto (Dirección Financiera y Optimización) requiere evaluar el **margen de contribución** de los 20 productos (con márgenes entre 14,4 % y 94,2 %), se planifica para dichas fases una extensión analítica mediante la integración de las tablas de insumos (`ingredients`) y formulaciones (`product_ingredients`), permitiendo calcular el `costo_ingredientes_linea` y el `margen_contribucion_estimado`.
