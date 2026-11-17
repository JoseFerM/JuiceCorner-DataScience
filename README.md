# Juice Corner BD — Proyecto Integrador I
### Sistema Analítico Integral: OLTP Transaccional, Data Warehouse Dimensional y Visualizador Web

[![SQL Server](https://img.shields.io/badge/SQL_Server-2014_|_2016_|_2019_|_2022_|_2025-CC292B?style=flat&logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![PowerShell](https://img.shields.io/badge/ETL-PowerShell_.NET_SqlBulkCopy-5391FE?style=flat&logo=powershell&logoColor=white)](#paso-2-carga-masiva-de-datos-transaccionales)
[![GitHub Pages](https://img.shields.io/badge/Visualizador-GitHub_Pages_Demo-22c55e?style=flat&logo=githubpages&logoColor=white)](https://joseferm.github.io/JuiceCorner-DataScience/)
[![GitHub Repo](https://img.shields.io/badge/Repositorio-JoseFerM%2FJuiceCorner--DataScience-181717?style=flat&logo=github&logoColor=white)](https://github.com/JoseFerM/JuiceCorner-DataScience)
[![Calidad](https://img.shields.io/badge/Calidad-ISO_8000_|_DMBOK_|_ISO_25012-f59e0b?style=flat&logo=checkmarx&logoColor=white)](#7-normativas-de-gobernanza-y-calidad-aplicadas)

---

## 1. Visión General del Proyecto

**Juice Corner BD** es un proyecto integral de ingeniería de datos desarrollado para el **Proyecto Integrador I (4to Semestre - Licenciatura en Ciencia de Datos)**. Centraliza y procesa la operativa completa de una cadena de restaurantes y servicio de delivery multicanal (pedidos en salón `dine_in`, para llevar `takeout` y entrega a domicilio `delivery`).

El proyecto abarca el ciclo de vida completo de los datos:
1. **Capa Transaccional (OLTP / TPS):** Modelo relacional normalizado en 3FN con 19 tablas optimizadas para alta concurrencia, integridad referencial y auditoría histórica.
2. **Capa de Extracción, Transformación y Carga (ETL):** Motor automatizado en PowerShell sobre .NET `SqlBulkCopy` con streaming y normalización de tipos.
3. **Capa Analítica (Data Warehouse):** Esquema en Estrella puro (*Kimball Dimensional Modeling*) con grano atómico por ítem de pedido, 7 dimensiones conformadas y métricas aditivas prorrateadas sin doble descuento.
4. **Capa de Gobernanza y Calidad:** Reglas alineadas con DMBOK, ISO/IEC 25012 e ISO 8000 con esquema administrativo dedicado (`audit.AUDITORIA_CUADRE_PEDIDOS`).
5. **Capa de Visualización:** Aplicación web interactiva completa (`index.html`) desplegada en **GitHub Pages** para consultar el diccionario de datos, diagramas ERD, guías de conexión y laboratorio SQL.

---

## 2. Arquitectura Global del Sistema

```mermaid
flowchart TD
    subgraph S1["1. Fuentes de Datos (Raw / Kaggle)"]
        CSV["Archivos CSV Transaccionales<br/>(37 entidades, >1.2 GB)"]
        PY["download_kaggle_dataset.py<br/>(kagglehub API)"]
    end

    subgraph S2["2. Motor Transaccional (JuiceCorner_OLTP)"]
        direction TB
        OLTP_CORE["19 Tablas Relacionales (3FN)<br/>• orders, order_items, payments<br/>• deliveries, delivery_tracking<br/>• products, categories, stock<br/>• customers, dining_tables"]
    end

    subgraph S3["3. Pipeline ETL Automatizado"]
        BULK["Cargar_Datos_OLTP.ps1<br/>(.NET SqlBulkCopy Streaming)"]
        BAT["Ejecutar_Carga.bat / ejecutar_sql.bat"]
    end

    subgraph S4["4. Data Warehouse Dimensional (JuiceCorner_DW)"]
        direction TB
        DIM_T["DIM_TIEMPO"] --> FACT["FACT_VENTAS<br/>(Grano Atómico: order_items.id)"]
        DIM_C["DIM_CLIENTE"] --> FACT
        DIM_P["DIM_PRODUCTO"] --> FACT
        DIM_S["DIM_SUCURSAL"] --> FACT
        DIM_Z["DIM_ZONA_ENTREGA"] --> FACT
        DIM_R["DIM_REPARTIDOR"] --> FACT
        DIM_M["DIM_METODO_PAGO"] --> FACT
        
        AUD["audit.AUDITORIA_CUADRE_PEDIDOS<br/>(Esquema Administrativo)"] -.-> FACT
    end

    subgraph S5["5. Visualización y Consumo"]
        WEB["Visualizador Web Interactivo<br/>(index.html / GitHub Pages)"]
        VSC["VS Code + Extensión mssql<br/>(.vscode/settings.json)"]
        SSMS["SQL Server Management Studio / Power BI"]
    end

    CSV --> PY
    CSV --> BULK
    BULK --> OLTP_CORE
    OLTP_CORE --> S4
    S4 --> WEB
    S4 --> VSC
    S4 --> SSMS
```

---

## 3. Estructura de las Bases de Datos

### A. Base Transaccional (`JuiceCorner_OLTP`)
Diseñada en T-SQL con restricciones de verificación (`CHECK`), claves primarias y foráneas con eliminación restringida (`ON DELETE NO ACTION / CASCADE`) para garantizar integridad transaccional.

| Módulo / Dominio | Tablas Incluidas | Propósito |
| :--- | :--- | :--- |
| **Ventas & Pedidos** | `orders`, `order_items`, `order_status_history` | Cabeceras, detalle a nivel de producto y trazabilidad de estados. |
| **Pagos & Finanzas** | `payments`, `refunds` | Transacciones monetarias, pasarelas de pago y devoluciones. |
| **Logística & Delivery** | `deliveries`, `delivery_personnel`, `delivery_zones`, `delivery_tracking` | Asignación de mensajeros, coordenadas GPS y zonas geográficas. |
| **Catálogo & Menú** | `categories`, `products`, `ingredients`, `product_ingredients` | Gestión del menú, combos, ingredientes y recetas. |
| **Clientes & Fidelización** | `customers`, `customer_addresses`, `loyalty_transactions`, `reviews` | Perfil del cliente, direcciones para entrega, monedero de puntos y reseñas. |
| **Operaciones en Salón** | `branches`, `dining_tables` | Sucursales físicas y mesas para pedidos presenciales. |
| **Inventario** | `suppliers`, `stock_movements` | Proveedores y control de existencias de insumos. |

### B. Modelo Dimensional (`JuiceCorner_DW` — Esquema Estrella Puro)
Construido bajo los principios de **Ralph Kimball** y auditado contra el Decálogo técnico oficial:

1. **Grano Atómico:** Una fila en `FACT_VENTAS` representa exactamente una línea de pedido (`order_items.id`), permitiendo máxima agregación sin pérdida de detalle.
2. **Desnormalización Estratégica:** `DIM_PRODUCTO` absorbe el nombre y la descripción de la categoría para evitar copos de nieve y agilizar consultas analíticas.
3. **Manejo Seguro de Claves Foráneas (Anti-Nulos):** Cada dimensión posee un registro comodín `sk = -1` (`Desconocido / No aplica`). Esto permite que pedidos presenciales (sin repartidor ni zona) o compras anónimas no violen la integridad referencial `NOT NULL`.
4. **Fórmula Corregida de `monto_neto` (Sin Doble Descuento):**
   $$\text{monto\_neto} = \text{subtotal} - \text{descuento\_cupon\_prorr} + \text{costo\_envio\_prorr} + \text{impuesto\_prorr}$$
   *Se evita restar dos veces el descuento, dado que `order_items.subtotal` ya viene descontado a nivel unitario.*
5. **Segregación del Esquema de Auditoría:** La tabla `AUDITORIA_CUADRE_PEDIDOS` reside en el esquema `audit` (`audit.AUDITORIA_CUADRE_PEDIDOS`) para no romper la topología estrella de cara a herramientas como Power BI o Tableau.

---

## 4. Visualizador Web Interactivo y Studio ERD

El proyecto incluye una aplicación web de consulta integral empaquetada en [`index.html`](index.html):

```text
+------------------------------------------------------------------------+
|  JUICE CORNER BD — Studio Interactivo de Arquitectura y Datos          |
+------------------------------------------------------------------------+
|  [Cómo Ejecutar]   [Diagramas ERD]   [Diccionario]   [Playground]      |
+------------------------------------------------------------------------+
```

### Funcionalidades del Visualizador:
- **Diagramas Interactivos:** Visualización gráfica del modelo relacional OLTP y del modelo estrella dimensional del Data Warehouse.
- **Diccionario de Tablas Completo:** Detalle campo por campo de tipos de datos, claves primarias, foráneas, valores nulos y descripciones.
- **Laboratorio de Consultas (Playground):** Consultas analíticas SQL preconstruidas (ventas por mes, productos más vendidos, ranking de repartidores, cuadre contable).
- **Cadenas de Conexión:** Snippets listos para copiar hacia LocalDB, SQL Express, Python (pyodbc, SQLAlchemy) y Power BI.
- **Modo Oscuro / Claro:** Interfaz responsiva con Tailwind CSS y Chart.js.

> [!TIP]
> **Visualizador Web en Línea (GitHub Pages):**
> La aplicación web interactiva se encuentra desplegada y disponible públicamente en:
> **[https://joseferm.github.io/JuiceCorner-DataScience/](https://joseferm.github.io/JuiceCorner-DataScience/)**

---

## 5. Guía de Ejecución Rápida (Local)

### Requisitos Previos
- Windows 10/11 o Windows Server.
- Microsoft SQL Server (LocalDB `(localdb)\MSSQLLocalDB`, SQLEXPRESS o instancia completa).
- Utilidad de línea de comandos `sqlcmd` (incluida en SQL Server o instalable vía MSODBCSQL).
- PowerShell 5.1 o PowerShell 7+.

### Paso 1: Inicialización con el Menú Interactivo
Ejecuta con doble clic el archivo [`ejecutar_sql.bat`](ejecutar_sql.bat) o mediante consola:
```cmd
.\ejecutar_sql.bat
```
El menú automatiza:
- Comprobación y arranque del servicio LocalDB.
- Creación de la base de datos `JuiceCorner_OLTP`.
- Creación de la base de datos `JuiceCorner_DW`.
- Reporte del conteo de tablas y registros.
- Apertura directa de VS Code o del Visualizador Web.

### Paso 2: Carga Masiva de Datos Transaccionales
Para poblar la base transaccional a partir de los datos CSV:
```cmd
.\Ejecutar_Carga.bat
```
O directamente desde PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\Cargar_Datos_OLTP.ps1
```

---

## 6. Estructura del Repositorio

```text
JuiceCorner-DataScience/
├── .vscode/
│   └── settings.json                                 # Perfil de conexión LocalDB para extensión mssql
├── dataset/                                          # Documentación del origen de datos
│   └── README.md                                     # Guía del dataset y política de archivos
├── Docs/                                             # Documentación técnica, justificaciones y entregables
│   ├── Decalogo_Data_Warehouse_Restaurante_Corregido.md # Decálogo Dimensional V2.0 oficial
│   ├── Informe_Cambios_Data_Warehouse.md               # Informe técnico de auditoría Kimball
│   ├── informe_justificacion_oltp.md                   # Justificación técnica del modelo OLTP
│   ├── Fase_1_Descuentos_y_Cupones_Juice_Corner.docx   # Documento de entrega - Fase 1
│   └── Data_Warehouse_TPS_Restaurante_Corregido.docx   # Documento de entrega - Data Warehouse
├── .gitignore                                        # Exclusión de CSVs masivos (>100MB) y temporales
├── Cargar_Datos_OLTP.ps1                             # Pipeline ETL automatizado (.NET SqlBulkCopy streaming)
├── download_kaggle_dataset.py                        # Descarga oficial del dataset vía API kagglehub
├── Ejecutar_Carga.bat                                # Lanzador batch para la carga masiva ETL
├── ejecutar_sql.bat                                  # Menú interactivo CLI para inicialización y pruebas
├── index.html                                        # Visualizador interactivo web (desplegado en GitHub Pages)
├── JuiceCorner_DW.sql                                # DDL del Data Warehouse dimensional (Modelo Estrella)
├── JuiceCorner_OLTP.sql                              # DDL de la base de datos transaccional (19 tablas 3FN)
└── README.md                                         # Portal de documentación centralizada del proyecto
```

---

## 7. Normativas de Gobernanza y Calidad Aplicadas

El diseño y transformación de datos siguen los tres pilares de gobernanza exigidos por el programa:

- **ISO/IEC 25012:** Garantía de exactitud sintáctica, completitud, consistencia matemática de los importes y trazabilidad de auditoría temporal en pedidos.
- **ISO 8000:** Calidad de datos maestros para clientes, productos y sucursales con identificadores unívocos (`nk` / natural keys) y surrogates (`sk`).
- **DMBOK (Data Management Body of Knowledge):** Separación explícita de modelos operacionales (3FN) y analíticos (Kimball), gestión de metadatos mediante diccionario vivo y reglas de prorrateo documentadas.

---

## 8. Equipo y Créditos

- **Proyecto:** Proyecto Integrador I — 4to Semestre
- **Institución:** Licenciatura en Ciencia de Datos / Ingeniería de Datos
- **Caso Empresarial:** Juice Corner BD — Cadena de Restaurantes & Delivery
