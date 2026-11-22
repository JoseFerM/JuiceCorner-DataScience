# CAPÍTULO I: MARCO INTRODUCTORIO

## TÍTULO DEL PROYECTO
**Diseño de una Política de Descuentos Alineada con la Rentabilidad por Producto, Mediante Análisis y Simulación de Escenarios, en Juice Corner BD de la Ciudad de Dhaka, Bangladesh**

---

## 1. PLANTEAMIENTO DEL PROBLEMA

### 1.1 Contextualización Empresarial
Juice Corner BD es una cadena comercial del sector gastronómico especializada en la elaboración y venta de jugos naturales, batidos y snacks, con tres sucursales operativas situadas en Dhaka, Bangladesh. La empresa comercializa un menú de 20 productos a través de dos canales principales: consumo en salón (*dine_in*) y servicio a domicilio (*delivery*), registrando sus transacciones en moneda local, el Taka bangladesí (BDT).

La base transaccional de estudio comprende un período de 160 días completos de operación comercial (equivalente a un semestre calendario de actividad regular), abarcando un universo de 1.000.000 de órdenes de compra, 2.498.660 líneas de detalle transaccional y 4.995.377 unidades físicas comercializadas.

### 1.2 Diagnóstico de la Situación Problemática
La rentabilidad operativa de Juice Corner BD se encuentra severamente erosionada debido a la aplicación de una política de descuentos empírica, dispersa y desprovista de criterios económicos de margen de contribución. Actualmente, la organización destina el **7,24 % de su subtotal neto a descuentos** (lo que representa 78.843.704 BDT: 52,35 millones correspondientes a descuentos directos de línea y 26,49 millones a cupones promocionales).

El análisis cuantitativo de los registros históricos pone de manifiesto tres distorsiones fundamentales:

1. **Desalineación Crítica entre Descuento y Margen por Producto:**
   Existe una relación inversa entre el descuento concedido y el margen de ganancia del producto. El producto con mayor margen de contribución de toda la carta (*Blue Lagoon Mocktail*, con un margen unitario de 94,2 %) recibe la tasa de descuento de línea más agresiva de la empresa (11,1 %). Por el contrario, el producto con el margen más reducido (*Strawberry Cream Shake*, con apenas un 14,4 % de margen) no recibe beneficio promocional alguno (0,0 %). 
   
   La correlación de Pearson calculada entre la tasa de descuento otorgada y el margen a precio de lista resulta negativa ($r = -0,19; p = 0,415$), ratificando estadísticamente la ausencia de una regla orientada al margen.

2. **Aplicación Global y Ciega de Cupones Promocionales:**
   El 38,65 % de las órdenes totales incluye un cupón de descuento. Estos cupones se deducen a nivel de canasta general sin evaluar la composición de rentabilidad de los artículos adquiridos, restando en promedio **68 BDT de margen neto por pedido** (generando una contribución promedio de 615 BDT en órdenes con cupón, frente a 653 BDT en órdenes sin cupón).

3. **Inconsistencias y Fuga de Reglas de Negocio en Cupones:**
   Los controles operativos del sistema de ventas evidencian vulnerabilidades críticas de gobernanza: el cupón `EID50` fue redimido fuera de su período de vigencia en el 94,4 % de sus aplicaciones; el cupón `VIP100` se concedió por debajo del importe mínimo de compra requerido en el 18,7 % de las transacciones; y la totalidad de los códigos promocionales vigentes sobrepasó el límite máximo de usos autorizados.

4. **Homogeneidad de Demanda que Invalida la Política Actual:**
   A diferencia de lo que justificaría una estrategia de liquidación o atracción comercial selectiva, el volumen de ventas se distribuye de manera estrictamente plana entre los 20 productos de la empresa (cada uno concentra aproximadamente el 5 % de las ventas totales, oscilando estrechamente entre 248.416 y 250.952 unidades vendidas, con un coeficiente de variación de apenas 0,26 %). Pruebas de hipótesis inferenciales (ANOVA con $p = 0,819$ y Kruskal-Wallis con $p = 0,908$) confirman que no existen diferencias estadísticamente significativas en la demanda de los productos. Por consiguiente, la asignación diferenciada de descuentos carece de fundamento operativo o de respuesta diferencial de mercado.

#### Tabla 1. Evidencia Cuantitativa de la Línea Base y Desalineación Estructural
| Indicador Clave | Valor Observado (Línea Base S0) | Interpretación Diagnóstica |
| :--- | :--- | :--- |
| **Costo Total de Descuentos s/ Subtotal Neto** | **7,24 %** (78.843.704 BDT) | Absorción desproporcionada del ingreso bruto de ventas |
| **Margen de Contribución Global (Pre-cupón)** | **61,1 %** | Por debajo del umbral corporativo objetivo (≥ 62,0 %) |
| **Margen de Contribución Global (Post-cupón)** | **60,1 %** | Pérdida adicional de 1,0 punto porcentual por promociones globales |
| **Productos con Descuento de Línea** | 9 de 20 productos (tasas: 6,7 % a 11,1 %) | Concentración arbitraria sin criterio de rotación |
| **Descuento en Producto de Mayor Margen** | 11,1 % (*Blue Lagoon Mocktail*, margen: 94,2 %) | Máxima erosión en el artículo más rentable |
| **Descuento en Producto de Menor Margen** | 0,0 % (*Strawberry Cream Shake*, margen: 14,4 %) | Nulo incentivo en productos con alto costo relativo |
| **Participación de Órdenes con Cupón** | **38,65 %** (386.495 órdenes) | Alta penetración promocional sin segmentación de canasta |
| **Pérdida de Margen por Orden con Cupón** | **-68 BDT** por pedido | Reducción de 653 BDT a 615 BDT por transacción |
| **Correlación Descuento vs. Margen ($r$)** | **$r = -0,19$** ($p = 0,415$) | Desalineación estructural: no existe correlación positiva |
| **Pruebas de Variación de Demanda** | ANOVA: $p = 0,819$ \| Kruskal-Wallis: $p = 0,908$ | Demanda homogénea; ningún producto justifica trato preferencial |

### 1.3 Consecuencias de la Inacción (Pronóstico del Problema)
De mantenerse el esquema actual de descuentos:
- **Concentración de Pérdidas:** Los 7 productos con margen de contribución inferior al 70 % continuarán absorbiendo 42,4 millones de BDT en beneficios (representando el 81 % del gasto en descuentos de línea y el 54 % del costo total de promociones), subsidiando ineficiencias de costo.
- **Sobrecosto Financiero:** La empresa continuará incurriendo en un exceso de gasto promocional de al menos **24,39 millones de BDT semestrales** respecto al estándar de mercado y meta institucional del 5,00 % del subtotal neto.
- **Estancamiento del Margen Operativo:** El margen de contribución global permanecerá confinado en torno al 60,1 % - 61,1 %, imposibilitando alcanzar la meta financiera mínima del 62,00 % requerida para la sostenibilidad y expansión de las sucursales.

### 1.4 Árbol del Problema

```
                                      EFECTOS / CONSECUENCIAS
 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │ • Margen global deprimido (61,1 %) por debajo del potencial financiero (meta: ≥62,0 %) │
 │ • Sobrecosto semestral de 24,39 millones de BDT en promociones no justificadas         │
 │ • Reducción directa de 68 BDT de margen por cada orden que aplica cupón                │
 └───────────────────────────────────────────┬────────────────────────────────────────────┘
                                             │
                                     PROBLEMA CENTRAL
 ┌───────────────────────────────────────────┴────────────────────────────────────────────┐
 │  POLÍTICA DE DESCUENTOS Y PROMOCIONES DESALINEADA DE LA RENTABILIDAD POR PRODUCTO      │
 │                     EN LAS SUCURSALES DE JUICE CORNER BD                               │
 └───────────────────────────────────────────┬────────────────────────────────────────────┘
                                             │
                                      CAUSAS RAÍCES
 ┌───────────────────────────────────────────┴────────────────────────────────────────────┐
 │ 1. Asignación arbitraria de descuentos de línea sin ponderación del margen unitario.   │
 │ 2. Cupones promocionales genéricos aplicados a canasta completa sin discriminar mix.   │
 │ 3. Falta de controles de negocio en cupones (fuga de fechas, montos mínimos y cupos).  │
 │ 4. Inexistencia de un modelo analítico de simulación de escenarios de optimización.   │
 └────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. FORMULACIÓN DEL PROBLEMA

### 2.1 Pregunta General de Investigación
> **¿Cómo puede un modelo de análisis y simulación de escenarios reducir la pérdida de margen ocasionada por el otorgamiento de descuentos desalineados con la rentabilidad de los 20 productos de Juice Corner BD, manteniendo constante el volumen de unidades vendidas, los precios de lista y la composición de la carta, durante su próximo semestre de operación en Dhaka, Bangladesh, a partir del análisis de las 1.000.000 de órdenes del semestre observado?**

---

## 3. OBJETIVOS DE LA INVESTIGACIÓN

### 3.1 Objetivo General
**Diseñar, mediante un modelo de análisis y simulación de escenarios, una política de descuentos para los 20 productos de Juice Corner BD, basada en el análisis de 1.000.000 de órdenes transaccionales, que permita, en el próximo semestre de operación de la empresa, reducir la proporción de descuentos otorgados del 7,24 % al 5,00 % o menos del subtotal neto y aumentar el margen de contribución global del 61,1 % al 62,0 % o más, manteniendo constante el volumen de unidades vendidas, los precios de lista y la composición de la carta.**

### 3.2 Objetivos Específicos
1. **OE1. Diagnosticar** la estructura histórica de descuentos (de línea y por cupones) y el margen de contribución individual de los 20 productos a partir de 1.000.000 de órdenes de compra.
   - *Entregable:* Tabla consolidada de línea base con indicadores de venta, descuentos y márgenes unitarios.
2. **OE2. Construir** un repositorio dimensional Data Warehouse (esquema estrella con 1 tabla de hechos `FACT_VENTAS` y 7 tablas de dimensiones) que garantice la consolidación, gobernanza e integridad contable de los datos.
   - *Entregable:* Base de datos relacional analítica validada con 0 inconsistencias en la auditoría de cuadre.
3. **OE3. Contrastar** estadísticamente la homogeneidad de la demanda diaria por producto y la correlación existente entre la tasa de descuento otorgada y el margen de ganancia a lista.
   - *Entregable:* Informe de pruebas estadísticas inferenciales (ANOVA, Kruskal-Wallis, Chi-cuadrado, Pearson y Spearman) con niveles de significancia ($\alpha = 0,05$).
4. **OE4. Estimar** la sensibilidad del comportamiento de la demanda y determinar el umbral de caída de volumen de equilibrio ante variaciones de descuento por canal, sucursal y categoría de producto.
   - *Entregable:* Modelo cuantitativo de elasticidad y matriz de límites de tolerancia de volumen de venta.
5. **OE5. Simular** escenarios de asignación promocional (línea base actual, reasignación moderada y optimización lineal orientada a margen) bajo volumen y carta constantes para el siguiente semestre operativo.
   - *Entregable:* Matriz comparativa de desempeño financiero y KPIs proyectados por escenario evaluado.
6. **OE6. Proponer** la política definitiva de descuentos diferenciados y la reglamentación estricta de cupones que satisfaga simultáneamente el costo de descuentos $\le 5,00 \%$ y un margen global $\ge 62,00 \%$.
   - *Entregable:* Manual de políticas comerciales, reglas de validación de cupones y programa de incentivos alineado al margen.

### 3.3 Matriz de Operacionalización SMART

| Objetivo | S (Específico) | M (Medible) | A (Alcanzable) | R (Relevante) | T (Temporal) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **General** | Política integral de descuentos alineada al margen por producto. | Costo de descuento $\le 5,00\%$; margen global $\ge 62,00\%$; correlación $r > 0$. | Demanda plana demostrada y volumen constante; ajuste de 0,9 pp de margen. | Corrige la principal causa de fuga de rentabilidad operativa. | Próximo semestre de operación de la empresa (S1). |
| **OE1** | Diagnóstico de línea base transaccional y rentabilidad. | 1.000.000 órdenes analizadas; 7,24 % costo de descuento; 61,1 % margen. | Datos transaccionales completos disponibles y validados. | Base empírica indispensable de comparación y evaluación. | Semestre observado (S0). |
| **OE2** | Data Warehouse con esquema dimensional en estrella. | 2.498.660 hechos consolidados; subtotal 1.089.008.540 BDT; 0 descuadres. | Infraestructura SQL Server y procesos ETL optimizados. | Garantiza veracidad y trazabilidad única de la información. | Semestre observado (S0). |
| **OE3** | Contraste inferencial de demanda y política actual. | Pruebas paramétricas y no paramétricas al 95 % de confianza ($\alpha=0,05$). | Scripts automatizados ejecutados en lenguaje R. | Demuestra la arbitrariedad empírica del modelo comercial actual. | Semestre observado (S0). |
| **OE4** | Modelación de elasticidad y caída de volumen de equilibrio. | Coeficientes de sensibilidad e intervalo de tolerancia de caída de volumen. | Métodos estadísticos y programación matemática formal. | Calibra el riesgo comercial de reducción de descuentos. | Parámetros de S0 proyectados a S1. |
| **OE5** | Simulación de escenarios comerciales proyectados. | Proyección cuantitativa de BDT, porcentaje de descuento y margen en 3 modelos. | Modelo de programación lineal bajo volumen constante. | Permite seleccionar el escenario óptimo con base científica. | Próximo semestre de operación (S1). |
| **OE6** | Formulación de la política definitiva de descuentos. | Costo final $\le 5,00\%$ y margen $\ge 62,00\%$ demostrados en simulación. | Ahorro semestral de hasta 24,39 millones de BDT. | Constituye la solución gerencial definitiva al problema central. | Próximo semestre de operación (S1). |

### 3.4 Horizonte Temporal de Evaluación y Metas Comparativas

El desempeño de la política propuesta se evalúa en el marco temporal de la empresa (semestre operativo proyectado $S_1$), manteniendo las condiciones fundamentales de mercado del semestre observado ($S_0$): mismo volumen total de órdenes y unidades, idénticos precios de lista e igual composición de la carta comercial.

#### Tabla 2. Matriz de Metas de Desempeño: Semestre Observado vs. Proyección Semestral
| Indicador Clave de Rendimiento | $S_0$ Observado (Línea Base Histórica) | $S_1$ Inacción (Política Actual Replicada) | $S_1$ Meta (Política Propuesta) | Criterio de Éxito |
| :--- | :--- | :--- | :--- | :--- |
| **Volumen de Órdenes** | 1.000.000 | 1.000.000 | 1.000.000 | Constante |
| **Unidades Físicas Vendidas** | 4.995.377 | 4.995.377 | 4.995.377 | Constante |
| **Costo de Descuentos (% Subtotal)** | **7,24 %** | **7,24 %** | **$\le$ 5,00 %** | Reducción $\ge$ 2,24 pp |
| **Monto Semestral de Descuentos** | 78.843.704 BDT | 78.843.704 BDT | **$\le$ 54.450.427 BDT** | Ahorro $\ge$ 24,39M BDT |
| **Margen de Contribución Global** | **61,1 %** | **61,1 %** | **$\ge$ 62,0 %** | Incremento $\ge$ 0,9 pp |
| **Correlación Descuento vs. Margen** | $r = -0,19$ | $r = -0,19$ | **Positiva ($r > 0$)** | Alineación económica |

---

## 4. JUSTIFICACIÓN Y DELIMITACIÓN DE LA INVESTIGACIÓN

### 4.1 Justificación Teórica y Metodológica
Desde la perspectiva teórica, la fijación y otorgamiento de descuentos comerciales no debe concebirse como un recurso promocional indiscriminado, sino como una herramienta de optimización microeconómica supeditada al margen de contribución marginal. Metodológicamente, la investigación aporta un marco riguroso de analítica prescriptiva que enlaza la minería de datos transaccionales (Data Warehouse y ETL), la contrastación estadística inferencial y la simulación matemática de escenarios bajo condiciones operativas reales.

### 4.2 Justificación Práctica y Económica
La investigación responde a una necesidad crítica de gestión financiera en Juice Corner BD. La optimización del gasto promocional recupera al menos 24,39 millones de BDT en el semestre de aplicación sin recurrir a incrementos en los precios de venta al público ni requerir inversiones en infraestructura, fortaleciendo directamente el flujo operativo de la cadena gastronómica.

### 4.3 Delimitación de la Investigación
- **Delimitación Espacial:** Exclusivamente circunscrita a las tres sucursales operativas de la cadena Juice Corner BD en la ciudad de Dhaka, Bangladesh.
- **Delimitación Temporal:** Análisis fundamentado en la base semestral de 160 días completos de operación regular ($S_0$), con proyección de evaluación para el período semestral inmediato de operación ($S_1$).
- **Delimitación Operativa y de Alcance:** La investigación interviene única y estrictamente en las reglas de asignación de descuentos por producto y la gobernanza de cupones. Quedan explícitamente fuera del alcance variaciones en los precios de lista de la carta, modificación en recetas de insumos o cambios en la oferta de productos del menú.

---

## 5. MARCO METODOLÓGICO

### 5.1 Enfoque Metodológico: Cuantitativo
La investigación adopta un enfoque eminentemente **cuantitativo**. Se basa en un razonamiento formal deductivo que parte de los principios económicos de maximización de margen para contrastarlos frente al comportamiento empírico de un registro transaccional masivo de 1.000.000 de órdenes. La recolección y procesamiento se efectúa sobre datos numéricos estructurados, aplicando pruebas estadísticas inferenciales con un nivel de significancia prefijado de $\alpha = 0,05$.

### 5.2 Diseño de la Investigación: No Experimental y Transversal Analítico
- **No Experimental:** Las variables operativas (precios de venta, costos de insumos, frecuencias de compra y descuentos) se analizan en su condición natural histórica, sin manipulación deliberada sobre el mercado físico. Los efectos de las nuevas directrices se evalúan a través de modelos computacionales de simulación.
- **Transversal Analítico:** Si bien el registro abarca una serie temporal de 160 días, el análisis central se estructura de forma consolidada por producto, canal y sucursal sobre la ventana semestral completa, habiéndose verificado la ausencia de tendencias seculares, quiebres estacionales o efectos por día de la semana.

### 5.3 Tipo y Alcance de la Investigación: Correlacional y Explicativo
- **Alcance Correlacional:** Evalúa el grado de asociación cuantitativa entre el porcentaje de descuento asignado a cada ítem y su respectivo margen de contribución, midiendo la dispersión y el sentido del coeficiente de Pearson y Spearman.
- **Alcance Explicativo:** Determina las causas estructurales que originan la erosión de beneficios (descuentos desalineados, canibalización por cupones ciegos y demanda homogénea no reactiva) y cuantifica formalmente el impacto marginal que la reestructuración de descuentos ejercerá sobre la rentabilidad global.

### 5.4 Sistema de Hipótesis

#### Hipótesis de Investigación ($H_i$)
> **$H_i$:** El diseño y aplicación de una política de descuentos comerciales alineada con el margen de contribución por producto permite reducir el costo total de descuentos al 5,00 % o menos del subtotal neto y elevar el margen de contribución global de Juice Corner BD al 62,00 % o más, manteniendo constantes el volumen de unidades vendidas, los precios de lista y la carta comercial durante el próximo semestre de operación.

#### Hipótesis Nula ($H_0$)
> **$H_0$:** Ninguna política de descuentos comerciales estructurada a partir del margen de contribución permite reducir el costo de descuentos al 5,00 % o menos y elevar simultáneamente el margen global al 62,00 % o más bajo condiciones de volumen y carta constantes.

#### Hipótesis Estadísticas Secundarias
1. **Correlación Descuento - Margen:**
   - $H_{0,1}: \rho = 0$ (No existe correlación lineal entre la tasa de descuento de línea y el margen de contribución del producto).
   - *Resultado empírico:* $r = -0,19$ ($p = 0,415$). No se rechaza $H_0$; se corrobora que la política histórica no premia la rentabilidad.
2. **Homogeneidad de Demanda entre Productos:**
   - $H_{0,2}: \mu_1 = \mu_2 = \dots = \mu_{20}$ (El volumen diario de unidades vendidas es idéntico entre los 20 productos de la carta).
   - *Resultado empírico:* ANOVA $F = 0,695, p = 0,819$; Kruskal-Wallis $\chi^2 = 10,75, p = 0,908$. No se rechaza $H_0$; la demanda es uniforme y no sustenta descuentos diferenciales por rotación.

### 5.5 Métodos, Técnicas e Instrumentos de Investigación
- **Métodos Teóricos:**
  - *Método Hipotético-Deductivo:* Planteamiento de conjeturas de rentabilidad y contrastación cuantitativa con la evidencia empírica del repositorio analítico.
  - *Método Analítico-Sintético:* Descomposición de la transaccionalidad por niveles (producto, cupón, canal, sucursal) y posterior síntesis en un modelo normativo corporativo.
- **Técnicas y Herramientas Tecnológicas:**
  - *Extracción, Transformación y Carga (ETL):* Procedimientos automatizados en scripts PowerShell (.NET `SqlBulkCopy`) y paquetes SSIS para ingesta de datos.
  - *Almacenamiento y Modelado Dimensional:* Sistema Gestor de Bases de Datos Microsoft SQL Server, estructurado bajo arquitectura de Data Warehouse dimensional (esquema en estrella).
  - *Análisis Estadístico e Inferencia:* Entorno RStudio / Lenguaje R para ejecución de tests de normalidad, contrastes de hipótesis (ANOVA, Kruskal-Wallis) y matrices de correlación.
  - *Optimización y Simulación:* Modelos de programación lineal determinista y evaluación estocástica de escenarios de demanda.

### 5.6 Población, Censo y Fuentes de Información
- **Población Objeto de Estudio:** Finita y exhaustiva, constituida por la totalidad del registro transaccional semestral: **1.000.000 de órdenes de compra**, **2.498.660 líneas de pedido**, **20 artículos de menú**, **3 sucursales comerciales** y **6 cupones promocionales**.
- **Criterio Muestral:** No se extrae muestra probabilística ni se calcula tamaño muestral; se efectúa un **censo poblacional íntegro (100 % de los registros)** gracias a la capacidad de procesamiento de la arquitectura analítica implementada, eliminando errores de muestreo.
- **Fuentes de Información:**
  - *Fuente Secundaria:* Base de datos transaccional estandarizada de restaurante y delivery (repositorio estructurado verificado e implementado en las bases `JuiceCorner_OLTP` y `JuiceCorner_DW`).

---

## 6. REFERENCIAS BIBLIOGRÁFICAS

- Bernal, C. A. (2016). *Metodología de la investigación: Administración, economía, humanidades y ciencias sociales* (4.ª ed.). Pearson Educación de Colombia.
- Hernández-Sampieri, R., Fernández-Collado, C., & Baptista-Lucio, P. (2014). *Metodología de la investigación* (6.ª ed.). McGraw-Hill Education.
- Kimball, R., & Ross, M. (2013). *The Data Warehouse Toolkit: The Definitive Guide to Dimensional Modeling* (3rd ed.). John Wiley & Sons.
- thesohanur. (s. f.). *Restaurant & Food Delivery Relational Database* [Conjunto de datos]. Kaggle. https://www.kaggle.com/datasets/thesohanur/restaurant-and-food-delivery-relational-database
- Universidad Privada del Valle. (2026). *Guía de aprendizaje. Capítulo I – Marco introductorio*. Departamento de Ingeniería de Sistemas e Informática.
