# DOCUMENTO B: APLICACIÓN AL PROYECTO INTEGRADOR (JUICE CORNER BD)
**Proyecto:** Juice Corner BD — Sistema TPS, Data Warehouse y Modelización Empresarial  
**Asignatura:** Modelización Empresarial I  
**Institución:** Universidad del Valle (UNIVALLE) — LCD 4to Semestre  
**Docente de Cátedra:** MSc. Karen G. Meneses M.  

---

## 1. ESPECIFICACIÓN DEL MODELO DE DEMANDA Y DIMENSIÓN MUESTRAL
Para modelar el comportamiento del consumidor y responder a la consigna de optimización de precios y márgenes de **Juice Corner BD**, se especificó la siguiente ecuación log-lineal con efectos fijos:

$$\ln(Q_{it}) = \beta_0 + \beta_1 \ln(P_{it}) + \beta_2 D_{it} + \beta_3 \text{Desc}_{it} + \delta_1 \text{Delivery}_{it} + \gamma_1 \text{Sucursal}_2 + \gamma_2 \text{Sucursal}_3 + u_{it}$$

### Dimensiones del Sistema Matricial:
$$\mathbf{y}_{(19,440 \times 1)} = \mathbf{X}_{(19,440 \times 7)} \boldsymbol{\beta}_{(7 \times 1)} + \mathbf{u}_{(19,440 \times 1)}$$

* **Tamaño muestral ($n = 19,440$):**  
  $$20\text{ Productos} \times 162\text{ Días de historial} \times 3\text{ Sucursales} \times 2\text{ Canales (Salón / Delivery)} = \mathbf{19,440\text{ observaciones}}$$
* **Cantidad de parámetros ($k = 7$):**  
  $\boldsymbol{\beta} = [\beta_0, \beta_1, \beta_2, \beta_3, \delta_1, \gamma_1, \gamma_2]'$.

---

## 2. MAPEO DIMENSIONAL DEL DATA WAREHOUSE A LA MATRIZ $\mathbf{X}$ Y AL VECTOR $\mathbf{y}$

El Data Warehouse implementado en [JuiceCorner_DW.sql](file:///C:/Users/Agents/Documents/3.1proyecto/JuiceCorner_DW.sql) abastece con total autosuficiencia todas las variables requeridas:

| Componente | Variable | Rol en el Modelo | Tabla / Dimensión del DW | Campo de Origen y Regla de Agregación |
| :---: | :--- | :--- | :--- | :--- |
| **Vector $\mathbf{y}$** | $\ln(Q_{it})$ | Log Cantidad Demandada | **Hecho:** `dbo.FACT_VENTAS` | Medida aditiva `quantity`. Agregada como $\sum \text{quantity} = Q_{it}$, transformada con $\ln(Q_{it})$. |
| **Columna 1** | $\mathbf{1}$ | Intercepto ($\beta_0$) | *Álgebra Lineal* | Columna de Unos ($1.0$). Anclaje matemático para $\beta_0$. |
| **Columna 2** | $\ln(P_{it})$ | Log Precio Promedio ($\beta_1$) | `dbo.FACT_VENTAS` + `dbo.DIM_PRODUCTO` | Campo `unit_price`. Promedio efectivo del ítem en la celda diaria, transformado con $\ln(P_{it})$. |
| **Columna 3** | $D_{it}$ | Descuento de Línea ($\beta_2$) | `dbo.FACT_VENTAS` | Medidas `descuento_linea`, `unit_price`, `quantity`: $(\text{descuento\_linea} / (\text{unit\_price} \times \text{quantity})) \times 100$. |
| **Columna 4** | $\text{Desc}_{it}$ | Intensidad Cupón ($\beta_3$) | `dbo.FACT_VENTAS` | Medidas `descuento_cupon_prorr` y `subtotal`: $(\text{descuento\_cupon\_prorr} / \text{subtotal}) \times 100$. |
| **Columna 5** | $\text{Delivery}_{it}$ | Dummy Canal ($\delta_1$) | `dbo.FACT_VENTAS` | Atributo degenerado `tipo_pedido`: $1$ si es `'delivery'`, $0$ si es `'dine_in'`. |
| **Columna 6** | $\text{Sucursal}_2$ | Dummy Gulshan ($\gamma_1$) | `dbo.DIM_SUCURSAL` (vía `sucursal_key`) | Clave foránea `sucursal_key` conectada a `branch_id_nk = 2`: $1$ si es Gulshan, $0$ en otro caso. |
| **Columna 7** | $\text{Sucursal}_3$ | Dummy Banani ($\gamma_2$) | `dbo.DIM_SUCURSAL` (vía `sucursal_key`) | Clave foránea `sucursal_key` conectada a `branch_id_nk = 3`: $1$ si es Banani, $0$ en otro caso. |

---

## 3. DEFINICIÓN DE CATEGORÍAS BASE Y PREVENCIÓN DE SINGULARIDAD EN $\mathbf{X}'\mathbf{X}$

Para resolver $\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}$, la matriz $\mathbf{X}'\mathbf{X}$ debe ser invertible ($\det(\mathbf{X}'\mathbf{X}) \neq 0$).

Si para una variable cualitativa con $m$ opciones se incluyeran $m$ variables dicotómicas además de la columna de unos, su suma reproduciría la primera columna:

$$\sum_{j=1}^m D_{ij} = \mathbf{1} = x_{i0}$$

Esto provoca **multicolinealidad exacta**, $\text{rango}(\mathbf{X}) < k$, $\det(\mathbf{X}'\mathbf{X}) = 0$, colapsando el estimador MCO por indeterminación matemática (*Dummy Variable Trap*).

### Categorías Base Seleccionadas para Juice Corner:
1. **Canal de Venta ($m = 2$):** Categoría Base Omitida = **`dine_in` (Consumo en Salón)**.
2. **Sucursales Físicas ($m = 3$):** Categoría Base Omitida = **Sucursal 1: Dhanmondi (Sede Matriz Principal)**.

**Garantía Matricial Lograda:**
* Rango verificado: $\text{rango}(\mathbf{X}) = 7$ (Rango de columnas completo).
* Determinante: $\det(\mathbf{X}'\mathbf{X}) = 1.1848 \times 10^{28} \neq 0$.
* Condición de número: $537$ (Muy inferior al umbral de riesgo de $1,000$).

---

## 4. SCRIPT EN PYTHON Y VERIFICACIÓN MATRICIAL 1:1

El archivo reproducible [ejecucion_matricial_y_statsmodels.py](file:///C:/Users/Agents/Documents/3.1proyecto/ejecucion_matricial_y_statsmodels.py) demuestra la identidad numérica absoluta entre el álgebra con NumPy y la librería `statsmodels`:

```python
import numpy as np
import pandas as pd
import statsmodels.api as sm

# Cargar dataset del DW
df = pd.read_csv('resultados_modelizacion/dataset_regresion_mco.csv')

# Formulación Matricial Pura con NumPy
X_vars = ['ln_P', 'D_it_avg', 'Desc_it_avg', 'Delivery_it', 'Sucursal_2', 'Sucursal_3']
X = np.hstack([np.ones((len(df), 1)), df[X_vars].values])
y = df['ln_Q'].values.reshape(-1, 1)

# Solución analítica beta = (X'X)^(-1) X'y
XtX = X.T @ X
inv_XtX = np.linalg.inv(XtX)
beta_matricial = (inv_XtX @ (X.T @ y)).flatten()

# Verificación con statsmodels (MCO Robusto HC1)
X_sm = sm.add_constant(df[X_vars])
modelo_hc1 = sm.OLS(df['ln_Q'], X_sm).fit(cov_type='HC1')
```

**Resultado de Identidad:** $|\hat{\beta}_{\text{matricial}} - \hat{\beta}_{\text{statsmodels}}| < 10^{-11}$ en los 7 parámetros.

---

## 5. RESULTADOS DE LA ESTIMACIÓN Y UTILIDAD PARA OBJETIVOS Y KPIS

### Tabla de Resultados Econométricos Oficiales (Errores Robustos HC1):

| Variable / Parámetro | Coeficiente ($\hat{\beta}$) | Error Estándar (HC1) | Estadístico $z$ | $p$-valor | Diagnóstico Econométrico |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Constante (`const`, $\beta_0$)** | **$+5.9523$** | $0.057$ | $104.70$ | $< 0.001$ | Demanda base en salón y sede matriz Dhanmondi. |
| **Log Precio (`ln_P`, $\beta_1$)** | **$-0.0792$** | $0.009$ | $-8.63$ | $< 0.001$ | Demanda inelástica ($|\beta_1| = 0.079 < 1$). |
| **Descuento Línea (`D_it_avg`, $\beta_2$)** | **$+0.0006$** | $0.0002$ | $+2.74$ | $0.006$ | Descuento ineficiente (+0.06% por pp). |
| **Cupón Orden (`Desc_it_avg`, $\beta_3$)** | **$-0.0113$** | $0.001$ | $-10.18$ | $< 0.001$ | Canibalización de ventas ($-1.13\%$ por pp). |
| **Canal Delivery (`Delivery_it`, $\delta_1$)** | **$+0.2009$** | $0.002$ | $105.70$ | $< 0.001$ | Canal prioritario (+20.09% vs. salón). |
| **Sucursal Gulshan (`Sucursal_2`, $\gamma_1$)** | $-0.0023$ | $0.002$ | $-0.99$ | $0.323$ | No significativa ($p > 0.05$). Comportamiento homogéneo. |
| **Sucursal Banani (`Sucursal_3`, $\gamma_2$)** | $-0.0028$ | $0.002$ | $-1.21$ | $0.227$ | No significativa ($p > 0.05$). Comportamiento homogéneo. |

*Estadísticos Globales:* $R^2 = 0.3692$; Estadístico $F = 1,874$ ($p < 0.0001$); $n = 19,440$.

---

## 6. MEDICIÓN DE KPIS Y CUMPLIMIENTO DEL OBJETIVO GENERAL

El **Objetivo General del Proyecto Integrador** consiste en:
> *"Reducir la proporción de descuentos otorgados del 7.24% al 5.00% o menos del subtotal neto y aumentar el margen de contribución global del 61.1% al 62.0% o más, manteniendo constante el volumen de unidades vendidas y los precios de lista."*

Los resultados del modelo econométrico fundamentan y cumplen las metas del proyecto de la siguiente forma:

1. **KPI Elasticidad Precio de la Demanda ($\beta_1 = -0.0792$):**  
   Al ser fuertemente inelástica, la empresa tolera eliminar descuentos sin perder clientela. Reducir los descuentos del 7.24% al 5.00% (un recorte neto de 2.24 pp) contrae el volumen físico de ventas en apenas un **$0.18\%$**, lo cual confirma la condición de *"mantener constante el volumen de unidades vendidas"*.
2. **KPI Eficiencia Promocional ($\beta_2 = +0.0006$):**  
   Demuestra que los descuentos directos otorgan un beneficio comercial casi nulo (+0.06% de demanda por 1 pp de descuento), validando su eliminación para sanear el margen de la carta.
3. **KPI Control de Canibalización ($\beta_3 = -0.0113$):**  
   El coeficiente negativo prueba que los cupones generales estaban subsidiando ventas existentes sin generar rotación neta. Su recorte directo libera fondos que incrementan automáticamente el margen de contribución al $62.0\%$.
4. **KPI Expansión del Canal Delivery ($\delta_1 = +0.2009$):**  
   El canal de entrega a domicilio genera un **$+20.09\%$** más de demanda que el salón tradicional. Es el canal estratégico para canalizar el volumen comercial de la empresa.
5. **KPI Homogeneidad de Red ($\gamma_1, \gamma_2$ no significativas):**  
   Al ser Gulshan ($p = 0.323$) y Banani ($p = 0.227$) indistinguibles de la sede central, se respalda la unificación de precios y promociones a nivel de toda la cadena, evitando costos de personalización por zona en el Data Warehouse.
