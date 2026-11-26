# GUIA DE ESTUDIO: ENFOQUE MATRICIAL EN MODELOS DE REGRESION MULTIPLE (MCO)
**Asignatura:** Modelizacion Empresarial I  
**Institucion:** Universidad del Valle (UNIVALLE) — Facultad de Ciencias Empresariales  
**Aplicacion:** Proyecto Integrador — Juice Corner BD (LCD 4to Semestre)  
**Docente de referencia:** MSc. Karen G. Meneses M.  

---

## INTRODUCCION
En todos los modelos econometricos desarrollados en el Proyecto Integrador, la estimacion mediante **Minimos Cuadrados Ordinarios (MCO)** se formula mediante el algebra matricial:

$$\mathbf{y} = \mathbf{X}\boldsymbol{\beta} + \mathbf{u} \quad \Longrightarrow \quad \mathbf{\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}}$$

Los modelos son lineales en los parametros $\boldsymbol{\beta}$ y se resuelven bajo la misma solucion analitica cerrada directa.

---

## APARTADO 1: LINEALIDAD EN LOS PARAMETROS — CONCLUSION DEL PROYECTO

> **Conclusion Fundamental para el Proyecto Integrador (Juice Corner):**  
> El modelo econometrico de demanda estimado:
> $$\ln(Q_{it}) = \beta_0 + \beta_1 \ln(P_{it}) + \beta_2 D_{it} + \beta_3 \text{Desc}_{it} + \delta_1 \text{Delivery}_{it} + \gamma_1 \text{Sucursal}_2 + \gamma_2 \text{Sucursal}_3 + u_{it}$$
> **es estrictamente lineal en los parametros $\beta$**, a pesar de contener logaritmos naturales en la cantidad y en el precio, ya que los coeficientes entran de forma aditiva y con exponente unitario.  
> Por tanto, el modelo se fundamenta en la ecuacion matricial universal $\mathbf{y} = \mathbf{X}\boldsymbol{\beta} + \mathbf{u}$ y su solucion cerrada se obtiene directamente como:
> $$\mathbf{\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}}$$

---

## APARTADO 2: ESTRUCTURA, DIMENSIONES Y DETERMINACION MUESTRAL ($n = 19,440$)

### 2.1 Determinacion del Tamaño Muestral y Nivel de Agregacion ($n = 19,440$)
El dataset para la regresion se construyo agregando las ventas en un formato panel multidimensional diario:

$$\underbrace{20}_{\text{Productos}} \times \underbrace{162}_{\text{Dias de registro}} \times \underbrace{3}_{\text{Sucursales}} \times \underbrace{2}_{\text{Canales (Delivery / Salon)}} = \mathbf{19,440 \text{ observaciones}}$$

* **20 Productos:** Catalogo completo analizado (mocktails, smoothies, licuados, sandwiches, ensaladas).
* **162 Dias:** Rango historico total registrado en la base de datos operativa / Data Warehouse.
* **3 Sucursales:** Dhanmondi (sucursal base), Gulshan ($\text{Sucursal}_2$) y Banani ($\text{Sucursal}_3$).
* **2 Canales:** Salon (`dine_in`, categoria base) vs. Pedido a domicilio (`delivery`).

Por consiguiente, el vector dependiente $\mathbf{y}$ tiene $19,440$ filas y la matriz de regresores $\mathbf{X}$ tiene dimension $19,440 \times 7$.

### 2.2 Conformabilidad Matricial
El sistema de ecuaciones simultaneas se expresa en bloques matriciales:

$$\underbrace{\mathbf{y}}_{(19,440 \times 1)} = \underbrace{\mathbf{X}}_{(19,440 \times 7)} \cdot \underbrace{\boldsymbol{\beta}}_{(7 \times 1)} + \underbrace{\mathbf{u}}_{(19,440 \times 1)}$$

| Componente | Dimension | Rol Matematico | En el Proyecto Integrador (Juice Corner) |
| :--- | :---: | :--- | :--- |
| **Vector $\mathbf{y}$** | $n \times 1$ | Variable dependiente observada | $19,440 \times 1$ observaciones de $\ln(Q_{it})$ (logaritmo de la cantidad vendida). |
| **Matriz $\mathbf{X}$** | $n \times k$ | Matriz de diseño con variables explicativas y dummies | Matriz de $19,440 \times 7$. Su primera columna son unos ($\mathbf{1}$), seguida de $\ln(P)$, $D$, $\text{Desc}$, $\text{Delivery}$, $\text{Suc}_2$ y $\text{Suc}_3$. |
| **Vector $\boldsymbol{\beta}$** | $k \times 1$ | Parametros desconocidos a estimar | $k = 7$ coeficientes: $[\beta_0, \beta_1, \beta_2, \beta_3, \delta_1, \gamma_1, \gamma_2]'$. |
| **Vector $\mathbf{u}$** | $n \times 1$ | Factores estocasticos no observados | Perturbaciones no capturadas (clima, eventos atipicos, etc.). |

### 2.3 Aspectos Clave de la Matriz $\mathbf{X}$
1. **Columna de Unos ($\mathbf{1}$):** Al realizar la multiplicacion de la fila $i$ de $\mathbf{X}$ por el vector $\boldsymbol{\beta}$, se genera $1 \cdot \beta_0 + x_{i1}\beta_1 + \dots$. El valor $1$ actua como el enganche algebraico que permite sumar el termino constante $\beta_0$. Sin esta columna, el modelo pasaria por el origen.
2. **Definicion de $k$:** $k$ es el numero total de parametros a estimar, incluyendo la constante $\beta_0$. Al existir 6 variables explicativas mas el intercepto, $k = 1 + 6 = 7$.

---

## APARTADO 3: DEDUCCION MATEMATICA DE LA SOLUCION CERRADA $\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}$

### 3.1 Criterio de Minimos Cuadrados
Se busca el vector $\hat{\boldsymbol{\beta}}$ que minimice la Suma de Cuadrados de los Residuos ($S$):
$$S(\hat{\boldsymbol{\beta}}) = \hat{\mathbf{u}}'\hat{\mathbf{u}} = (\mathbf{y} - \mathbf{X}\hat{\boldsymbol{\beta}})'(\mathbf{y} - \mathbf{X}\hat{\boldsymbol{\beta}})$$

### 3.2 Expansion Matricial
Desarrollando los productos mediante propiedades de transpuesta:
$$S(\hat{\boldsymbol{\beta}}) = \mathbf{y}'\mathbf{y} - \mathbf{y}'\mathbf{X}\hat{\boldsymbol{\beta}} - \hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{y} + \hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{X}\hat{\boldsymbol{\beta}}$$

Dado que $\mathbf{y}'\mathbf{X}\hat{\boldsymbol{\beta}}$ es un escalar ($1 \times 1$), es identico a su transpuesta $\hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{y}$:
$$S(\hat{\boldsymbol{\beta}}) = \mathbf{y}'\mathbf{y} - 2\hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{y} + \hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{X}\hat{\boldsymbol{\beta}}$$

### 3.3 Condicion de Primer Orden (CPO)
Derivando con respecto a $\hat{\boldsymbol{\beta}}$ e igualando al vector nulo:
$$\frac{\partial S}{\partial \hat{\boldsymbol{\beta}}} = -2\mathbf{X}'\mathbf{y} + 2\mathbf{X}'\mathbf{X}\hat{\boldsymbol{\beta}} = \mathbf{0} \quad \Longrightarrow \quad \mathbf{X}'\mathbf{X}\hat{\boldsymbol{\beta}} = \mathbf{X}'\mathbf{y} \quad \text{(Ecuaciones Normales de Gauss)}$$

### 3.4 Despeje Formal
Multiplicando a la izquierda por la matriz inversa $(\mathbf{X}'\mathbf{X})^{-1}$:
$$(\mathbf{X}'\mathbf{X})^{-1}(\mathbf{X}'\mathbf{X})\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y} \quad \Longrightarrow \quad \mathbf{\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}}$$

---

## APARTADO 4: VALORES AJUSTADOS ($\hat{\mathbf{y}}$), MATRIZ DE PROYECCION ($\mathbf{H}$) Y RESIDUOS ESTIMADOS ($\hat{\mathbf{u}}$)

### 4.1 Valores Ajustados y la Matriz Hat ($\mathbf{H}$)
Las predicciones del modelo dentro de la muestra se calculan como:
$$\hat{\mathbf{y}} = \mathbf{X}\hat{\boldsymbol{\beta}} = \mathbf{X}(\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y} = \mathbf{H}\mathbf{y}$$

Donde $\mathbf{H} = \mathbf{X}(\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'$ se denomina **Matriz Hat o de Proyeccion** (orden $n \times n = 19,440 \times 19,440$).

**Propiedades Matematicas de $\mathbf{H}$:**
1. **Simetria:** $\mathbf{H}' = \mathbf{H}$.
2. **Idempotencia:** $\mathbf{H}\mathbf{H} = \mathbf{H}$ (proyectar sobre un subespacio ya proyectado conserva el mismo resultado).
3. **Traza:** $\text{tr}(\mathbf{H}) = \text{rango}(\mathbf{X}) = k = 7$ (la suma de los elementos de su diagonal principal es igual al numero de parametros).
4. **Apalancamiento (*Leverage*):** Los elementos diagonales $h_{ii}$ miden la influencia potencial que posee la observacion $i$ sobre sus propios valores ajustados.

### 4.2 Residuos Estimados y la Matriz Aniquiladora ($\mathbf{M}$)
El residuo representa la variabilidad no explicada por el hiperplano del modelo:
$$\hat{\mathbf{u}} = \mathbf{y} - \hat{\mathbf{y}} = \mathbf{y} - \mathbf{H}\mathbf{y} = (\mathbf{I}_n - \mathbf{H})\mathbf{y} = \mathbf{M}\mathbf{y}$$

Donde $\mathbf{M} = \mathbf{I}_n - \mathbf{H}$ es la **matriz generadora de residuos o aniquiladora** (con $\mathbf{I}_n$ siendo la matriz identidad de orden $19,440$).

**Propiedades Matematicas de $\mathbf{M}$:**
1. **Simetrica e Idempotente:** $\mathbf{M}' = \mathbf{M}$ y $\mathbf{M}\mathbf{M} = \mathbf{M}$.
2. **Traza y Grados de Libertad:** $\text{tr}(\mathbf{M}) = \text{tr}(\mathbf{I}_n) - \text{tr}(\mathbf{H}) = n - k = 19,440 - 7 = 19,433$ grados de libertad del modelo.
3. **Ortogonalidad Fundamental:** $\mathbf{X}'\hat{\mathbf{u}} = \mathbf{0}$. Los residuos son estrictamente perpendiculares al espacio generado por las columnas de $\mathbf{X}$, garantizando que no contengan informacion lineal de los predictores.
4. **Suma Nula:** Al contar con intercepto, la ortogonalidad garantiza que $\sum_{i=1}^n \hat{u}_i = 0$.

---

## APARTADO 5: INFERENCIA ESTADISTICA

La inferencia estadistica se estimo con errores estandar robustos HC1 para corregir heterocedasticidad y validar la significancia ($p$-valores) de cada coeficiente.

---

## APARTADO 6: APLICACION AL PROYECTO INTEGRADOR (JUICE CORNER BD)

### 6.1 Mapeo Dimensional del DW hacia el Vector y y la Matriz X
El modelo econometrico se alimenta directamente del esquema en estrella del Data Warehouse (DW), tomando como nucleo la tabla de hechos `FACT_VENTAS` (grano: linea de pedido) agregada por producto, dia, sucursal y canal de venta:

| Variable Matricial | Columna en Script | Tabla de Hechos DW | Dimensiones Vinculadas | Operacion / Atributo DW |
| :--- | :--- | :--- | :--- | :--- |
| **Vector $\mathbf{y}$** ($\ln Q_{it}$) | `ln_Q` | `dbo.FACT_VENTAS` | `DIM_PRODUCTO`, `DIM_SUCURSAL`, `DIM_TIEMPO` | $\ln(\sum \text{quantity})$: Suma aditiva de unidades vendidas por grupo. |
| **Columna $\mathbf{1}$** ($\beta_0$) | `const` | Diseño analitico | No aplica | Vector unitario generado por `sm.add_constant()` para el intercepto. |
| **Columna 2** ($\ln P_{it}$) | `ln_P` | `dbo.FACT_VENTAS` | Transaccional | $\ln(\text{AVG}(\text{unit\_price}))$: Promedio del precio efectivo facturado. |
| **Columna 3** ($D_{it}$) | `D_it_avg` | `dbo.FACT_VENTAS` | Transaccional | $\text{AVG}((\text{descuento\_linea} / (\text{unit\_price} \cdot \text{quantity})) \cdot 100)$: Tasa de descuento de producto. |
| **Columna 4** ($\text{Desc}_{it}$) | `Desc_it_avg` | `dbo.FACT_VENTAS` | Transaccional / Cabecera | $\text{AVG}((\text{descuento\_cupon\_prorr} / \text{subtotal}) \cdot 100)$: Intensidad del cupon sobre la orden. |
| **Columna 5** ($\text{Delivery}_{it}$) | `Delivery_it` | `dbo.FACT_VENTAS` | Atributo degenerado | Variable dicotomica: 1 si `tipo_pedido = 'delivery'`, 0 si `tipo_pedido = 'dine_in'`. |
| **Columna 6** ($\text{Sucursal}_2$) | `Sucursal_2` | `dbo.FACT_VENTAS` | `dbo.DIM_SUCURSAL` | Dummy: 1 si `sucursal_key = 2` (Gulshan), 0 en otro caso. |
| **Columna 7** ($\text{Sucursal}_3$) | `Sucursal_3` | `dbo.FACT_VENTAS` | `dbo.DIM_SUCURSAL` | Dummy: 1 si `sucursal_key = 3` (Banani), 0 en otro caso. |

### 6.2 Definicion de Categorias Base para Evitar Singularidad en X'X
Para incluir variables cualitativas en un modelo con intercepto $\beta_0$, se debe evitar la **trampa de las variables ficticias** (multicolinealidad exacta). Si una variable posee $m$ categorias y se incorporan las $m$ variables dicotomicas, la suma de sus columnas coincide exactamente con la columna de unos ($\sum_{j=1}^m D_j = \mathbf{1}$). En consecuencia, el determinante $\det(\mathbf{X}'\mathbf{X}) = 0$ y la matriz resulta no invertible (singular).

* **Canal de Venta (2 estados: Delivery vs. Salon):**
  * **Categoria Base:** Consumo en salon (`dine_in`).
  * **Tratamiento:** Se omitio la dummy de salon y se incluyo solo `Delivery_it`.
  * **Efecto en el modelo:** El intercepto $\beta_0$ refleja el volumen base en salon. El coeficiente $\delta_1 = +0.2009$ mide el diferencial porcentual neto de delivery respecto a salon.
* **Sucursales (3 locales: Dhanmondi, Gulshan, Banani):**
  * **Categoria Base:** Sucursal 1 (Dhanmondi, sede central).
  * **Tratamiento:** Se omitio la dummy de Dhanmondi y se incorporaron `Sucursal_2` y `Sucursal_3`.
  * **Efecto en el modelo:** El intercepto $\beta_0$ contiene el nivel de Dhanmondi. Los parametros $\gamma_1$ y $\gamma_2$ miden si las otras sedes difieren significativamente de la base.

### 6.3 Desglose Estructural del CSV (dataset_regresion_mco.csv) y Ejecucion en Python
El archivo `dataset_regresion_mco.csv` ($19,440$ filas) no es un volcado plano sin procesar, sino un conjunto de datos estructurado en tres capas funcionales que responden a los requerimientos de la regresion matricial:

| Capa Funcional | Columna | Tipo de Dato | Por que existe y que funcion cumple en el analisis |
| :--- | :--- | :--- | :--- |
| **A. Claves del Panel**<br>*(Grano dimensional)* | `product_id` | Entero (1 a 20) | Identificador unico del producto en el DW. Permite el seguimiento de cada item del menu. |
| | `name` | Texto (String) | Nombre comercial legible (ej. *Pure Mango Splash*). Facilita la auditoria y lectura de resultados. |
| | `fecha` | Fecha (AAAA-MM-DD) | Fecha de corte diaria (162 dias consecutivos). Controla la evolucion temporal de la demanda. |
| | `branch_id` | Entero (1, 2, 3) | Identificador de sucursal (1: Dhanmondi, 2: Gulshan, 3: Banani). Modela disparidades locales. |
| | `order_type` | Texto (String) | Canal original (`delivery` o `dine_in`). Base para construir la variable dicotomica de canal. |
| **B. Metricas Fisicas**<br>*(Escala natural)* | `Q_it` | Entero | Cantidad fisica agregada vendida en la celda diaria. Medida base de demanda real. |
| | `P_it_avg` | Decimal (BDT) | Precio unitario medio efectivo facturado ese dia. Refleja el precio real pagado tras promociones. |
| | `D_it_avg` | Decimal (%) | Tasa porcentual promedio de descuento directo a nivel de linea de producto (0% a 100%). |
| | `Desc_it_avg` | Decimal (%) | Intensidad del cupon de cabecera prorrateado sobre el subtotal de la orden (0% a 100%). |
| | `n_ordenes` | Entero | Numero de ordenes que incluyeron el producto. Métrica de control de transacciones / flujo. |
| **C. Variables MCO**<br>*(Entrada matricial)* | `ln_Q` | Decimal continuo | **Vector dependiente $\mathbf{y}$:** $\ln(Q_{it})$. Estabiliza la varianza y permite estimar elasticidades directas. |
| | `ln_P` | Decimal continuo | **Regresor en $\mathbf{X}$:** $\ln(P_{it\_avg})$. Su coeficiente $\beta_1$ es la elasticidad precio directa ($\% \Delta Q / \% \Delta P$). |
| | `Delivery_it` | Binario (0 o 1) | **Dummy de canal en $\mathbf{X}$:** 1 si es delivery, 0 si es salon (base). Previene singularidad en $\mathbf{X}'\mathbf{X}$. |
| | `Sucursal_2` | Binario (0 o 1) | **Dummy de sucursal en $\mathbf{X}$:** 1 si es Gulshan, 0 en otro caso. Compara Gulshan frente a Dhanmondi. |
| | `Sucursal_3` | Binario (0 o 1) | **Dummy de sucursal en $\mathbf{X}$:** 1 si es Banani, 0 en otro caso. Compara Banani frente a Dhanmondi. |

#### Adaptacion de Nombres y Script en Python (statsmodels)
Para alimentar la ecuacion $\mathbf{y} = \mathbf{X}\boldsymbol{\beta} + \mathbf{u}$, se extrae el vector `ln_Q` y la lista de columnas `X_vars`, empleando `sm.add_constant()` para incluir la columna de unos del intercepto:

```python
import pandas as pd
import statsmodels.api as sm

# 1. Carga del dataset extraido del DW (19,440 observaciones)
df = pd.read_csv('resultados_modelizacion/dataset_regresion_mco.csv')

# 2. Definicion del vector dependiente y (19,440 x 1)
y = df['ln_Q']

# 3. Seleccion de las 6 variables explicativas que componen X
X_vars = ['ln_P', 'D_it_avg', 'Desc_it_avg', 'Delivery_it', 'Sucursal_2', 'Sucursal_3']

# 4. Adicion del vector unitario para beta_0 (genera matriz de 19,440 x 7)
X = sm.add_constant(df[X_vars])

# 5. Estimacion MCO clasica y con correccion robusta HC1 (Huber-White)
modelo_mco = sm.OLS(y, X).fit()
modelo_hc1 = sm.OLS(y, X).fit(cov_type='HC1')
print(modelo_hc1.summary())
```

* Diagnostico global: $R^2 = 0.369$, Estadistico $F = 1,874$ ($p < 0.001$), Grados de libertad residuales: $n - k = 19,433$.

### 6.4 Analisis de Resultados: Medicion de KPIs y Objetivos de Negocio

| Parametro | Variable | Coeficiente ($\hat{\beta}$) | Std. Error | $p$-valor | Utilidad para KPIs y Cumplimiento del Objetivo |
| :---: | :--- | :---: | :---: | :---: | :--- |
| $\beta_0$ | `const` | $+5.9523$ | $0.057$ | $< 0.001$ | **KPI Demanda Base:** Nivel minimo de ventas en salon sin promociones. Calibra capacidad de cocina. |
| $\beta_1$ | `ln_P` | **$-0.0792$** | $0.009$ | $< 0.001$ | **KPI Elasticidad Inelastica ($|\beta_1| = 0.079 < 1$):** Subir 1% en precio reduce volumen solo 0.079%. Permite retirar descuentos sin riesgo de perdida de demanda. |
| $\beta_2$ | `D_it_avg` | $+0.0006$ | $0.0002$ | $0.006$ | **KPI Eficiencia Promocional:** 1 pp de descuento apenas genera +0.06% de demanda. Demuestra que el descuento de lista es ineficiente. |
| $\beta_3$ | `Desc_it_avg` | **$-0.0113$** | $0.001$ | $< 0.001$ | **KPI Canibalizacion de Cupones:** 1 pp de cupon general reduce la demanda del item en -1.13%. Los cupones subsidian clientes preexistentes sin atraer volumen neto rentable. |
| $\delta_1$ | `Delivery_it` | **$+0.2009$** | $0.002$ | $< 0.001$ | **KPI Rendimiento de Canal:** Delivery vende **+20.09%** mas que salon. Prioriza la inversion operativa y logistica en este canal. |
| $\gamma_1$ | `Sucursal_2` | $-0.0023$ | $0.002$ | $0.323$ | **KPI Homogeneidad de Cadena:** Gulshan se comporta analogo a Dhanmondi ($p > 0.05$). Justifica unificar politica comercial. |
| $\gamma_2$ | `Sucursal_3` | $-0.0028$ | $0.002$ | $0.227$ | **KPI Homogeneidad de Cadena:** Banani no difiere de la base ($p > 0.05$). Consolida catalogo y precios unicos. |

> **Impacto en Margen y Rentabilidad:**  
> La reduccion de descuentos ineficientes (del 7.24% al 2.24% del subtotal) incrementa el **Margen de Contribucion Global de 58.64% a 61.25%**. La empresa tolera una caida de hasta **+7.70% en volumen** antes de perder margen, pero por inelasticidad ($\beta_1 = -0.0792$), el volumen solo se contrae un 0.28%.

---

## ANEXO TECNICO: CODIGO PYTHON Y SALIDA DEL MODELO ECONOMETRICO MCO

### 1. Codigo de Estimacion en Python (statsmodels)
Codigo puntual para la carga del dataset del Data Warehouse, definicion de variables dependiente e independientes, y ajuste MCO con correccion robusta HC1:

```python
import pandas as pd
import statsmodels.api as sm

# 1. Carga del dataset de regresion (panel: 19,440 observaciones)
DATA_PATH = 'resultados_modelizacion/dataset_regresion_mco.csv'
df = pd.read_csv(DATA_PATH)

# 2. Definicion del vector dependiente y (19,440 x 1)
y = df['ln_Q']

# 3. Definicion de la matriz de variables explicativas X
X_vars = [
    'ln_P',        # Logaritmo del precio promedio efectivo
    'D_it_avg',    # Tasa de descuento de producto (%)
    'Desc_it_avg', # Intensidad del cupon de orden (%)
    'Delivery_it', # Variable dicotomica (1=delivery, 0=dine_in)
    'Sucursal_2',  # Dummy de local (1=Gulshan, 0=Dhanmondi)
    'Sucursal_3'   # Dummy de local (1=Banani, 0=Dhanmondi)
]

# 4. Insercion del vector unitario para el intercepto beta_0 (genera matriz de 19,440 x 7)
X = sm.add_constant(df[X_vars])

# 5. Ajuste del modelo MCO clasico
modelo_ols = sm.OLS(y, X).fit()

# 6. Ajuste con errores estandar robustos HC1 (Huber-White)
modelo_hc1 = sm.OLS(y, X).fit(cov_type='HC1')

# 7. Despliegue de coeficientes y estadisticos
print(modelo_hc1.summary())
```

### 2. Salida Oficial de la Regresion (statsmodels OLS HC1)

```text
                            OLS Regression Results                            
==============================================================================
Dep. Variable:                   ln_Q   R-squared:                       0.369
Model:                            OLS   Adj. R-squared:                  0.369
Method:                 Least Squares   F-statistic:                     1874.
Date:                Wed, 25 Nov 2026   Prob (F-statistic):               0.00
Time:                        11:54:59   Log-Likelihood:                 11706.
No. Observations:               19440   AIC:                        -2.340e+04
Df Residuals:                   19433   BIC:                        -2.334e+04
Df Model:                           6                                         
Covariance Type:                  HC1                                         
===============================================================================
                  coef    std err          z      P>|z|      [0.025      0.975]
-------------------------------------------------------------------------------
const           5.9523      0.057    104.702      0.000       5.841       6.064
ln_P           -0.0792      0.009     -8.625      0.000      -0.097      -0.061
D_it_avg        0.0006      0.000      2.744      0.006       0.000       0.001
Desc_it_avg    -0.0113      0.001    -10.184      0.000      -0.014      -0.009
Delivery_it     0.2009      0.002    105.696      0.000       0.197       0.205
Sucursal_2     -0.0023      0.002     -0.989      0.323      -0.007       0.002
Sucursal_3     -0.0028      0.002     -1.207      0.227      -0.007       0.002
==============================================================================
Omnibus:                    15957.554   Durbin-Watson:                   1.174
Prob(Omnibus):                  0.000   Jarque-Bera (JB):           710187.766
Skew:                          -3.663   Prob(JB):                         0.00
Kurtosis:                      31.690   Cond. No.                         537.
==============================================================================

Notes:
[1] Standard Errors are heteroscedasticity robust (HC1)
```
