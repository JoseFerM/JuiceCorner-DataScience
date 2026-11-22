# Diseño de una Política de Descuentos Alineada con la Rentabilidad por Producto, Mediante Análisis y Simulación de Escenarios, en Juice Corner BD de la Ciudad de Dhaka, Bangladesh
### Proyecto Integrador I — Ingeniería de Sistemas / Ciencia de Datos (4to Semestre)

[![SQL Server](https://img.shields.io/badge/SQL_Server-2014_|_2016_|_2019_|_2022_|_2025-CC292B?style=flat&logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![PowerShell](https://img.shields.io/badge/ETL-PowerShell_.NET_SqlBulkCopy-5391FE?style=flat&logo=powershell&logoColor=white)](#paso-2-carga-masiva-de-datos-transaccionales)
[![GitHub Pages](https://img.shields.io/badge/Visualizador-GitHub_Pages_Demo-22c55e?style=flat&logo=githubpages&logoColor=white)](https://joseferm.github.io/JuiceCorner-DataScience/)
[![GitHub Repo](https://img.shields.io/badge/Repositorio-JoseFerM%2FJuiceCorner--DataScience-181717?style=flat&logo=github&logoColor=white)](https://github.com/JoseFerM/JuiceCorner-DataScience)
[![Calidad](https://img.shields.io/badge/Calidad-ISO_8000_|_DMBOK_|_ISO_25012-f59e0b?style=flat&logo=checkmarx&logoColor=white)](#10-normativas-de-gobernanza-y-calidad-aplicadas)

---

## Jerarquía Documental del Proyecto

Toda la arquitectura, ingeniería de datos, modelado analítico y código ejecutable del repositorio se subordinan formalmente a la siguiente jerarquía documental:

```text
  ┌────────────────────────────────────────────────────────────────────────┐
  │              NIVEL 1: CIMA Y BASE METODOLÓGICA RECTORA                 │
  │   Docs/Capitulo_I_Marco_Introductorio_Limpio.md (.html)               │
  │   - Título formal, árbol del problema y objetivos SMART (OE1 a OE6)    │
  │   - Sistema de hipótesis (Hi / H0) y marco metodológico cuantitativo   │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
  ┌───────────────────────────────────┴────────────────────────────────────┐
  │          NIVEL 2: INFORME DE AVANCE Y ENTREGABLE CONSOLIDADO           │
  │   Docs/Avance.docx                                                     │
  │   - Documento final formal de entrega ejecutiva de Fases 1, 2 y 3      │
  │   - Evidencias numéricas, validación de hipótesis y resultados en R    │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
  ┌───────────────────────────────────┴────────────────────────────────────┐
  │       NIVEL 3: ESPECIFICACIONES TÉCNICAS Y CALIBRACIÓN DE DATOS        │
  │   Docs/Informe_Ajuste_Temporal_1Anio.md (Marco temporal año móvil)     │
  │   Docs/Decalogo_Data_Warehouse_Restaurante_Corregido.md (Kimball DW)   │
  │   Docs/Informe_Cambios_Data_Warehouse.md (Auditoría y cuadre)          │
  │   Docs/informe_justificacion_oltp.md (Modelo 3FN de 19 tablas)         │
  └───────────────────────────────────┬────────────────────────────────────┘
                                      │
  ┌───────────────────────────────────┴────────────────────────────────────┐
  │          NIVEL 4: ARTEFACTOS TECNOLÓGICOS Y CÓDIGO OPERATIVO           │
  │   DDL: JuiceCorner_OLTP.sql, JuiceCorner_DW.sql                        │
  │   ETL: Cargar_Datos_OLTP.ps1, Ejecutar_Carga.bat, Crear_Backup.bat     │
  │   Visualizador: index.html (GitHub Pages) y visualizador_sql.html (v3) │
  └────────────────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **Documentos Oficiales Clave:**
> 1. **Cima y Marco Metodológico:** [`Docs/Capitulo_I_Marco_Introductorio_Limpio.md`](Docs/Capitulo_I_Marco_Introductorio_Limpio.md) (y [`Capitulo_I_Marco_Introductorio_Limpio.html`](Docs/Capitulo_I_Marco_Introductorio_Limpio.html)) define la formulación académica, el árbol del problema, las hipótesis y los objetivos específicos OE1 a OE6.
> 2. **Informe Final de Entrega:** [`Docs/Avance.docx`](Docs/Avance.docx) es el documento consolidado de entrega ejecutiva que agrupa las evidencias y contrastes de las Fases 1, 2 y 3.
> 3. **Horizonte de Análisis:** El estudio comprende **1 año de operación (1 año móvil: 22 de junio de 2025 al 21 de junio de 2026)** para la evaluación de estacionalidad y comportamiento de la demanda, documentado en [`Docs/Informe_Ajuste_Temporal_1Anio.md`](Docs/Informe_Ajuste_Temporal_1Anio.md).

---

## 1. Visión General del Proyecto

**Juice Corner BD** es una cadena comercial gastronómica especializada en la elaboración y venta de jugos naturales, batidos y snacks, con tres sucursales operativas situadas en Dhaka, Bangladesh. La empresa comercializa un menú de 20 productos a través de dos canales principales: consumo en salón (`dine_in`) y servicio a domicilio (`delivery`), registrando sus operaciones en Taka bangladesí (BDT).

El universo analizado comprende **1.000.000 de órdenes transaccionales**, **2.498.660 líneas de detalle** y **4.995.377 unidades físicas comercializadas**, realizando el análisis sobre **1 año completo de operación (1 año móvil: 22 de junio de 2025 al 21 de junio de 2026)**.

### Diagnóstico de la Situación Problemática
La rentabilidad operativa de Juice Corner BD se encuentra severamente erosionada debido a una política de descuentos empírica y desalineada del margen de contribución. Actualmente destina el **7,24 % de su subtotal neto a descuentos** (78.843.704 BDT: 52,35M en descuentos directos de línea y 26,49M en cupones promocionales):
- **Desalineación Crítica:** Existe una correlación negativa ($r = -0,19; p = 0,415$) entre tasa de descuento y margen del producto. El ítem con mayor margen (*Blue Lagoon Mocktail*, 94,2 %) recibe el descuento más alto (11,1 %), mientras que el de menor margen (*Strawberry Cream Shake*, 14,4 %) no recibe beneficio alguno.
- **Cupones Ciegos y Fuga de Reglas:** El 38,65 % de las órdenes utiliza cupón, deduciéndose sobre la canasta completa sin discriminar mix y restando en promedio **68 BDT de margen por pedido**. Además, cupones como `EID50` se aplicaron fuera de vigencia en el 94,4 % de sus usos y `VIP100` bajo el monto mínimo en el 18,7 %.
- **Homogeneidad de Demanda:** Los 20 productos venden prácticamente el mismo volumen (~5 % de la mezcla cada uno, CV = 0,26 %, ANOVA $p = 0,819$). Ningún producto justifica descuentos diferenciados por rotación.
- **Consecuencia Financiera:** La empresa incurre en un sobrecosto semestral de al menos **24,39 millones de BDT** respecto a la meta corporativa del 5,00 % del subtotal neto.

---

## 2. Objetivos de la Investigación y Sistema de Hipótesis

### Objetivo General
Diseñar, mediante un modelo de análisis y simulación de escenarios, una política de descuentos para los 20 productos de Juice Corner BD que permita, en el próximo período operativo de la empresa, reducir la proporción de descuentos del **7,24 % al 5,00 % o menos** del subtotal neto y aumentar el margen de contribución global del **61,1 % al 62,0 % o más**, manteniendo constantes el volumen de unidades vendidas, los precios de lista y la composición de la carta.

### Objetivos Específicos (OE1 a OE6)
1. **OE1. Diagnosticar** la estructura histórica de descuentos (de línea y por cupones) y el margen de contribución individual de los 20 productos a partir de 1.000.000 de órdenes.
2. **OE2. Construir** un repositorio dimensional Data Warehouse (esquema estrella con 1 tabla de hechos `FACT_VENTAS` y 7 dimensiones) que garantice consolidación, gobernanza e integridad contable sin descuadres.
3. **OE3. Contrastar** estadísticamente la homogeneidad de la demanda diaria y la correlación existente entre la tasa de descuento otorgada y el margen a precio de lista ($\alpha = 0,05$).
4. **OE4. Estimar** la sensibilidad de la demanda y determinar el umbral de caída de volumen de equilibrio ante variaciones de descuento por canal, sucursal y categoría.
5. **OE5. Simular** escenarios de asignación promocional (línea base actual, reasignación moderada y optimización lineal orientada a margen) bajo volumen y carta constantes.
6. **OE6. Proponer** la política definitiva de descuentos diferenciados y la reglamentación estricta de cupones que satisfaga simultáneamente el costo de descuentos $\le 5,00 \%$ y un margen global $\ge 62,00 \%$.

### Sistema de Hipótesis
- **Hipótesis de Investigación ($H_i$):** El diseño y aplicación de una política de descuentos comerciales alineada con el margen de contribución por producto permite reducir el costo total de descuentos al 5,00 % o menos del subtotal neto y elevar el margen de contribución global al 62,00 % o más, manteniendo constantes el volumen, precios y carta comercial.
- **Hipótesis Nula ($H_0$):** Ninguna política de descuentos estructurada a partir del margen permite reducir el costo al 5,00 % o menos y elevar el margen al 62,00 % o más bajo condiciones de volumen y carta constantes.
- **Hipótesis de Demanda ($H_{0,2}$):** $\mu_1 = \mu_2 = \dots = \mu_{20}$ (ANOVA $F = 0,695, p = 0,819$; Kruskal-Wallis $p = 0,908$, no se rechaza $H_0$; la demanda es uniforme).

---

## 3. Indicadores Clave de Rendimiento (KPIs)

| KPI | Fórmula de Cálculo | Línea Base Observada ($S_0$) | Meta Propuesta ($S_1$) | Verificación Metodológica |
| :--- | :--- | :--- | :--- | :--- |
| **Costo de Descuentos** | $\frac{\text{Descuentos de línea} + \text{Descuentos por cupón}}{\text{Subtotal neto}} \times 100$ | **7,24 %** (78,84M BDT) | **$\le$ 5,00 %** ($\le$ 54,45M BDT) | Fases 4 y 5 (OE5 / OE6) |
| **Margen de Contribución Global** | $\frac{\text{Ventas netas} - \text{Costo ingredientes}}{\text{Ventas netas}} \times 100$ | **61,07 %** (pre-cupón)<br>**60,10 %** (post-cupón) | **$\ge$ 62,00 %** | Fases 4 y 5 (OE5 / OE6) |
| **Alineación Descuento-Margen** | Correlación de Pearson ($r$) entre descuento y margen a lista | **$r = -0,19$** (desalineada / negativa) | **Positiva ($r > 0$)** | Fases 3 y 5 (OE3 / OE6) |
| **Ahorro Semestral Estimado** | Reducción de subsidios en productos con margen < 70 % | 0 BDT | **$\ge$ 24,39 Millones BDT** | Simulación de escenarios |

---

## 4. Estado de Avance por Fases (Fases 1 a 3)

### Fase 1: Identificación del Problema, Gobernanza y Modelo Relacional (OE1 - Completada)
- Delimitación espacial (3 sucursales en Dhaka), temporal (ventana anualizada auditada) y operativa.
- Diseño e implementación del modelo relacional transaccional (3FN) con 19 tablas en SQL Server (`JuiceCorner_OLTP.sql`).
- Alineamiento con normas **ISO 8000** (claves naturales `_nk`), **ISO/IEC 25012** (calidad del producto de datos) y **DMBOK**.

### Fase 2: Construcción y Organización de Datos (Data Warehouse & ETL) (OE2 - Completada)
- **Esquema Estrella Puro:** Tabla de hechos central `FACT_VENTAS` (grano atómico por línea `order_items.id`, 2.498.660 filas) y 7 dimensiones conformadas (`DIM_TIEMPO`, `DIM_CLIENTE`, `DIM_PRODUCTO`, `DIM_SUCURSAL`, `DIM_ZONA_ENTREGA`, `DIM_REPARTIDOR`, `DIM_METODO_PAGO`).
- **Eliminación de Nulos:** Claves sustitutas comodín `sk = -1` (`Desconocido / No aplica`) para compras anónimas o pedidos en salón.
- **Fórmula de Monto Neto Auditada:**
  $$\text{monto\_neto} = \text{subtotal} - \text{descuento\_cupon\_prorr} + \text{costo\_envio\_prorr} + \text{impuesto\_prorr}$$
- **Pipeline ETL Masivo:** Carga en streaming vía PowerShell (`Cargar_Datos_OLTP.ps1` y `Ejecutar_Carga.bat`) basada en .NET `SqlBulkCopy` con validación de 0 descuadres en `audit.AUDITORIA_CUADRE_PEDIDOS`.
- **Horizonte Temporal de 1 Año:** Cobertura de 1 año móvil continuo (22 de junio de 2025 al 21 de junio de 2026) que permite evaluar estacionalidad y comportamiento de la demanda sin alterar duraciones intradiarias ni valores contables ([`Docs/Informe_Ajuste_Temporal_1Anio.md`](Docs/Informe_Ajuste_Temporal_1Anio.md)).

### Fase 3: Análisis Estadístico e Inferencia en R (OE3 - Foco Actual)
- **Homogeneidad de Demanda:** ANOVA ($F = 0,70, p = 0,819$) y Kruskal-Wallis ($p = 0,908$) descartan diferencias de venta entre productos. Coeficiente $V$ de Cramér entre 0,0025 y 0,0077 demuestra que la mezcla es independiente de sucursal, canal o fecha.
- **Concentración del Desgaste Promocional:** 7 productos con margen menor al 70 % absorben **42,4 millones de BDT** (el 81 % del descuento de línea y 54 % del costo total promocional).
- **Infracción de Cupones:** 94,4 % de órdenes de `EID50` fuera de vigencia; 18,7 % de `VIP100` bajo el monto mínimo; y destrucción de 68 BDT de margen neto por orden con cupón.

---

## 5. Plan de Expansión Estratégica: Marketing y Finanzas (OE4 a OE6)

### A. Dimensión de Marketing (Fase 4 - OE4 / OE6)
- **Blindaje y Gobernanza de Cupones:** Bloqueo automático de redenciones fuera de vigencia y aplicación estricta de cupos por cliente.
- **Condicionamiento Selectivo de Canasta:** Restricción de cupones para excluir productos de margen vulnerable (< 50 %) y focalizarlos en líneas altamente rentables (> 70 %).
- **Umbrales Mínimos Dinámicos:** Configuración de montos mínimos de compra que garanticen rentabilidad incremental real.
- **Transición a Descuentos Estacionales:** Supresión de descuentos de línea estáticos en productos de bajo margen.

### B. Dimensión Financiera (Fase 4 y 5 - OE4 / OE5 / OE6)
- **Estructura Integral de Costos Operativos (COGS y Logística):** Modelado de empaque, mano de obra y comisiones de delivery.
- **Modelo de Optimización Lineal (Fase 5):** Maximización de la función objetivo de margen de contribución sujeta a costo de descuentos $\le 5,00\%$ y margen global $\ge 62,00\%$.
- **Cálculo de Caída de Volumen de Equilibrio:** Determinación matemática de la tolerancia máxima de reducción de demanda permisible al retirar un descuento sin mermar la utilidad neta en BDT.

---

## 6. Visualizador Web Interactivo y SQL Studio (v3)

El proyecto incluye un entorno de exploración analítica disponible en la nube y de forma local:

![Juice Corner BD — Visualizador y Ejecutor SQL Studio](Docs/visualizador_studio_preview.png)

```text
+------------------------------------------------------------------------+
|  JUICE CORNER BD — Studio Interactivo de Arquitectura y Datos (v3)     |
+------------------------------------------------------------------------+
|  [Cómo Ejecutar]   [Diagramas ERD]   [Diccionario]   [Playground SQL]  |
+------------------------------------------------------------------------+
```

### Funcionalidades de la Plataforma:
- **Diccionario de Tablas Completo (28 Tablas):** Especificación campo a campo de las 19 tablas del OLTP y las 9 tablas del Data Warehouse.
- **Laboratorio y Gráficos SQL:** Consultas analíticas predefinidas para validar ventas por mes, ranking de productos y cuadres contables.
- **Cadenas de Conexión:** Snippets listos para conectar Excel, Power BI, Python (pyodbc, SQLAlchemy) y Node.js.
- **Acceso Local:** Ejecutable haciendo doble clic en [`visualizador_sql.html`](visualizador_sql.html) o [`index.html`](index.html), o mediante la opción `[7]` del menú [`ejecutar_sql.bat`](ejecutar_sql.bat).
- **Despliegue en la Nube (GitHub Pages):** Disponible públicamente en:
  **[https://joseferm.github.io/JuiceCorner-DataScience/](https://joseferm.github.io/JuiceCorner-DataScience/)**

---

## 7. Arquitectura Global del Sistema

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
        BAT["Ejecutar_Carga.bat / Crear_Backup.bat"]
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
        WEB["Visualizador Web Interactivo<br/>(visualizador_sql.html / GitHub Pages)"]
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

## 8. Estructura del Repositorio

```text
JuiceCorner-DataScience/
├── .vscode/
│   └── settings.json                                 # Perfil de conexión LocalDB para extensión mssql
├── dataset/                                          # Documentación del origen de datos
│   └── README.md                                     # Guía del dataset y política de exclusión
├── Docs/                                             # Documentación técnica, metodológica y entregables
│   ├── Capitulo_I_Marco_Introductorio_Limpio.md      # CIMA Y MARCO RECTOR: Formulación, objetivos e hipótesis
│   ├── Capitulo_I_Marco_Introductorio_Limpio.html    # Versión formateada para consulta y lectura
│   ├── Avance.docx                                   # INFORME CONSOLIDADO DE ENTREGA (Fases 1, 2 y 3)
│   ├── Informe_Ajuste_Temporal_1Anio.md              # Documento de referencia de la ventana móvil de 1 año
│   ├── Decalogo_Data_Warehouse_Restaurante_Corregido.md # Decálogo Dimensional V2.0 oficial (Kimball)
│   ├── Informe_Cambios_Data_Warehouse.md               # Informe técnico de auditoría y cuadre de DW
│   ├── informe_justificacion_oltp.md                   # Justificación técnica del modelo OLTP (3FN)
│   └── visualizador_studio_preview.png               # Captura de pantalla de la plataforma SQL & BI Studio
├── .gitignore                                        # Exclusión de CSVs masivos (>100MB), node_modules y temporales
├── Cargar_Datos_OLTP.ps1                             # Pipeline ETL automatizado (.NET SqlBulkCopy streaming)
├── download_kaggle_dataset.py                        # Descarga oficial del dataset vía API kagglehub
├── Ejecutar_Carga.bat                                # Lanzador batch para la carga masiva ETL
├── Crear_Backup.bat                                  # Generador y validador de copia de seguridad .BAK
├── ejecutar_sql.bat                                  # Menú interactivo CLI para inicialización y pruebas
├── index.html                                        # Visualizador interactivo web (GitHub Pages)
├── visualizador_sql.html                             # Visualizador interactivo web v3 (copia local de estudio)
├── JuiceCorner_DW.sql                                # DDL del Data Warehouse dimensional (Modelo Estrella)
├── JuiceCorner_OLTP.sql                              # DDL de la base de datos transaccional (19 tablas 3FN)
└── README.md                                         # Portal de documentación centralizada del proyecto
```

---

## 9. Guía de Puesta en Marcha (Local)

### Requisitos Previos
- Microsoft SQL Server (LocalDB `(localdb)\MSSQLLocalDB`, SQLEXPRESS o instancia completa).
- Utilidad de línea de comandos `sqlcmd`.
- PowerShell 5.1 o superior.

### Paso 1: Inicialización con el Menú Interactivo
Ejecuta el archivo [`ejecutar_sql.bat`](ejecutar_sql.bat):
```cmd
.\ejecutar_sql.bat
```
El menú automatiza:
- Arranque del servicio LocalDB.
- Creación de la base de datos transaccional `JuiceCorner_OLTP`.
- Creación del Data Warehouse dimensional `JuiceCorner_DW`.
- Comprobación del estado de las 28 tablas.
- Apertura del Visualizador Web Interactivo (Opción 7).

### Paso 2: Carga Masiva de Datos Transaccionales
Para cargar el dataset a SQL Server:
```cmd
.\Ejecutar_Carga.bat
```

### Paso 3: Generación de Copia de Seguridad (.BAK)
Para crear un respaldo completo y validado de la base transaccional:
```cmd
.\Crear_Backup.bat
```

---

## 10. Normativas de Gobernanza y Calidad Aplicadas

- **ISO/IEC 25012:** Garantía de exactitud sintáctica, completitud, consistencia matemática de importes netos y trazabilidad temporal.
- **ISO 8000:** Calidad de datos maestros en clientes, productos y sucursales con identificadores naturales (`nk`) y sustitutos (`sk`).
- **DMBOK (Data Management Body of Knowledge):** Separación explícita de modelos operacionales (3FN) y analíticos (Kimball), gestión de metadatos mediante diccionario vivo y reglas de prorrateo documentadas.

---

## 11. Equipo y Créditos

- **Proyecto:** Proyecto Integrador I — 4to Semestre
- **Institución:** Licenciatura en Ciencia de Datos / Ingeniería de Sistemas — Universidad Privada del Valle
- **Caso Empresarial:** Juice Corner BD — Dhaka, Bangladesh
