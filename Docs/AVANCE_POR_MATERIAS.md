# Bases y Avance por Materias — Proyecto Integrador I (Juice Corner BD)

Este documento consolida la estructura documental de [`Docs/`](./) organizada por **materias principales**, detallando sus **fundamentos teóricos/técnicos (bases)**, los **entregables asociados** y el **estado real de avance** dentro del proyecto **Juice Corner BD** (Dhaka, Bangladesh — 1.000.000 de órdenes, 2.498.660 líneas, período original de **162 días: 11/01/2026 al 21/06/2026**, ~5,5 meses).

---

## Mapa General de Avance por Materia

| # | Materia / Área | Carpeta | Fase / OE | Estado |
| :--- | :--- | :--- | :--- | :--- |
| 0 | **Proyecto Integrador (Marco Metodológico)** | [`00_Proyecto_Integrador/`](00_Proyecto_Integrador/) | Transversal (OE1–OE6) | **Completada (Cap. I y Avance)** |
| 1 | **Ingeniería de Datos y Base de Datos (OLTP + DW)** | [`01_Ingenieria_Datos_DW/`](01_Ingenieria_Datos_DW/) | Fases 1 y 2 (OE1, OE2) | **Completada (100 %)** |
| 2 | **Estadística e Inferencia** | [`02_Estadistica/`](02_Estadistica/) | Fase 3 (OE3) | **Completada (100 %)** |
| 3 | **Modelización Empresarial I (Econometría MCO)** | [`03_Modelizacion_MCO/`](03_Modelizacion_MCO/) | Fase 4 (OE4, OE5) | **Completada (100 %)** |
| 4 | **Optimización (Programación Lineal)** | [`04_Optimizacion/`](04_Optimizacion/) | Fase 5 (OE5, OE6) | **En Curso (Diseño / Formulación LP)** |
| 5 | **Finanzas y Marketing** | [`05_Finanzas_y_Marketing/`](05_Finanzas_y_Marketing/) | Fase 5 (OE1, OE6) | **En Curso (Diagnóstico listo / Reglas en diseño)** |

---

## Detalle por Materia

### 0. Proyecto Integrador — Marco Metodológico Rector
- **Carpeta:** [`Docs/00_Proyecto_Integrador/`](00_Proyecto_Integrador/)
- **Bases:** Planteamiento del problema, árbol del problema, objetivos SMART (Objetivo General y OE1–OE6), sistema de hipótesis ($H_i, H_0, H_{0,2}$) y delimitación temporal sobre el dataset original de **162 días** (11/01/2026 al 21/06/2026, ~5,5 meses / semestre base $S_0$) para calibrar las metas del próximo semestre ($S_1$: costo de descuentos $\le 5,00\%$ del subtotal neto y margen global $\ge 62,00\%$).
- **Documentos clave:**
  - [`Capitulo_I_Marco_Introductorio_Limpio.md`](00_Proyecto_Integrador/Capitulo_I_Marco_Introductorio_Limpio.md) (y `.html`)
  - [`Avance.docx`](00_Proyecto_Integrador/Avance.docx) / [`Avance_Adaptado_Capitulo_I.md`](00_Proyecto_Integrador/Avance_Adaptado_Capitulo_I.md) (`.html`, `.docx`)

### 1. Ingeniería de Datos y Base de Datos (OLTP + Data Warehouse)
- **Carpeta:** [`Docs/01_Ingenieria_Datos_DW/`](01_Ingenieria_Datos_DW/)
- **Bases:** Modelado relacional en Tercera Forma Normal (3FN, 19 tablas en [`JuiceCorner_OLTP.sql`](../JuiceCorner_OLTP.sql)), arquitectura dimensional Kimball en esquema estrella (`FACT_VENTAS` + 7 dimensiones en [`JuiceCorner_DW.sql`](../JuiceCorner_DW.sql)), gobernanza **ISO 8000**, **ISO/IEC 25012** y **DMBOK**, claves sustitutas comodín (`sk = -1`) y carga masiva streaming mediante `.NET SqlBulkCopy` ([`Cargar_Datos_OLTP.ps1`](../Cargar_Datos_OLTP.ps1)).
- **Documentos clave:**
  - [`informe_justificacion_oltp.md`](01_Ingenieria_Datos_DW/informe_justificacion_oltp.md)
  - [`Decalogo_Data_Warehouse_Restaurante_Corregido.md`](01_Ingenieria_Datos_DW/Decalogo_Data_Warehouse_Restaurante_Corregido.md)
  - [`Informe_Cambios_Data_Warehouse.md`](01_Ingenieria_Datos_DW/Informe_Cambios_Data_Warehouse.md)

### 2. Estadística e Inferencia
- **Carpeta:** [`Docs/02_Estadistica/`](02_Estadistica/)
- **Bases:** Contraste de hipótesis ($\alpha = 0,05$), pruebas paramétricas y no paramétricas de homogeneidad de demanda (ANOVA, Kruskal-Wallis), asociación categórica ($V$ de Cramér) y correlación lineal (Pearson $r$) entre tasa de descuento y margen a precio de lista.
- **Documento de materia:** [`BASES_Y_AVANCE_ESTADISTICA.md`](02_Estadistica/BASES_Y_AVANCE_ESTADISTICA.md)

### 3. Modelización Empresarial I (Econometría MCO)
- **Carpeta:** [`Docs/03_Modelizacion_MCO/`](03_Modelizacion_MCO/)
- **Bases:** Regresión lineal múltiple en notación matricial ($\mathbf{y} = \mathbf{X}\boldsymbol{\beta} + \mathbf{u}$, estimador $\hat{\boldsymbol{\beta}} = (\mathbf{X}^\top \mathbf{X})^{-1}\mathbf{X}^\top \mathbf{y}$), especificación log-lineal de demanda sobre panel balanceado de 19.440 observaciones, errores estándar robustos **White HC1**, diagnósticos (Jarque-Bera, Breusch-Pagan, VIF), simulación de escenarios (E1, E2) y análisis de sensibilidad (umbral de quiebre 7,70 %).
- **Documentos clave:**
  - [`BASES_Y_AVANCE_MODELIZACION.md`](03_Modelizacion_MCO/BASES_Y_AVANCE_MODELIZACION.md)
  - [`Documento_A_Analisis_Ejemplo_Guia_MCO.md`](03_Modelizacion_MCO/Documento_A_Analisis_Ejemplo_Guia_MCO.md)
  - [`Documento_B_Aplicacion_Proyecto_Integrador_MCO.md`](03_Modelizacion_MCO/Documento_B_Aplicacion_Proyecto_Integrador_MCO.md)
  - [`Guia_Estudio_Enfoque_Matricial_MCO.md`](03_Modelizacion_MCO/Guia_Estudio_Enfoque_Matricial_MCO.md) (y `.docx`)
  - [`Identificacion_DW_y_Estimacion_Matricial_MCO.md`](03_Modelizacion_MCO/Identificacion_DW_y_Estimacion_Matricial_MCO.md)
  - Código y salidas: [`modelizacion_mco.py`](../modelizacion_mco.py), [`ejecucion_matricial_y_statsmodels.py`](../ejecucion_matricial_y_statsmodels.py), [`reporte_modelizacion_mco.html`](../reporte_modelizacion_mco.html)

### 4. Optimización (Programación Lineal)
- **Carpeta:** [`Docs/04_Optimizacion/`](04_Optimizacion/)
- **Bases:** Investigación de Operaciones / Programación Lineal (LP con **PuLP** en Python): maximización del margen de contribución global (Escenario E3) sujeto a restricciones de presupuesto promocional ($\le 5,00\%$ del subtotal neto), piso de margen ($\ge 62,00\%$), volumen constante y cotas por producto/canal.
- **Documento de materia:** [`BASES_Y_AVANCE_OPTIMIZACION.md`](04_Optimizacion/BASES_Y_AVANCE_OPTIMIZACION.md)

### 5. Finanzas y Marketing
- **Carpeta:** [`Docs/05_Finanzas_y_Marketing/`](05_Finanzas_y_Marketing/)
- **Bases:** Estructura de costos (COGS / ingredientes, empaque, logística y comisiones de delivery), margen de contribución pre-cupón y post-cupón, diagnóstico de erosión comercial (78,84M BDT en descuentos; 68 BDT perdidos por orden con cupón), gobernanza y blindaje de cupones (`EID50`, `VIP100`), y focalización en el canal `delivery` (+22,3 % volumen).
- **Documento de materia:** [`BASES_Y_AVANCE_FINANZAS_MARKETING.md`](05_Finanzas_y_Marketing/BASES_Y_AVANCE_FINANZAS_MARKETING.md)
