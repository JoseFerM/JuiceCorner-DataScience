# DOCUMENTO A: ANÁLISIS DEL EJEMPLO Y FUNDAMENTOS DE LA GUÍA MATRICIAL MCO
**Materia:** Modelización Empresarial I  
**Institución:** Universidad del Valle (UNIVALLE) — Facultad de Ciencias Empresariales  
**Carrera:** Licenciatura en Ciencia de Datos (LCD), 4to Semestre  
**Docente de Cátedra:** MSc. Karen G. Meneses M.  

---

## 1. INTRODUCCIÓN Y MARCO CONCEPTUAL
En la econometría moderna y la ciencia de datos, el tratamiento de modelos con múltiples variables explicativas y grandes volúmenes de observaciones abandona las sumatorias escalares manuales ($\sum x_i y_i$) y se formula bajo el **álgebra matricial**.

Cualquier modelo lineal en los parámetros adopta la estructura fundamental:

$$\mathbf{y} = \mathbf{X}\boldsymbol{\beta} + \mathbf{u}$$

Donde:
* $\mathbf{y} \in \mathbb{R}^{n \times 1}$: Vector columna que contiene las $n$ observaciones de la variable dependiente.
* $\mathbf{X} \in \mathbb{R}^{n \times k}$: Matriz de diseño donde la primera columna es un vector de unos ($\mathbf{1}$) para el intercepto $\beta_0$, y las restantes $k-1$ columnas representan las variables explicativas continuas y variables dicotómicas (*dummies*).
* $\boldsymbol{\beta} \in \mathbb{R}^{k \times 1}$: Vector de coeficientes teóricos a estimar: $[\beta_0, \beta_1, \dots, \beta_{k-1}]'$.
* $\mathbf{u} \in \mathbb{R}^{n \times 1}$: Vector de perturbaciones aleatorias inobservadas.

---

## 2. DEDUCCIÓN MATEMÁTICA DE LA SOLUCIÓN CERRADA $\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}$

El principio de Mínimos Cuadrados Ordinarios (MCO) consiste en hallar el vector de coeficientes estimados $\hat{\boldsymbol{\beta}}$ que **minimice la Suma de Cuadrados de los Residuos (SCR)**.

### Paso 1: Definición del vector de residuos
$$\hat{\mathbf{u}} = \mathbf{y} - \hat{\mathbf{y}} = \mathbf{y} - \mathbf{X}\hat{\boldsymbol{\beta}}$$

### Paso 2: Función objetivo de error cuadrático
Expresando la suma de cuadrados como producto interno:
$$S(\hat{\boldsymbol{\beta}}) = \hat{\mathbf{u}}'\hat{\mathbf{u}} = (\mathbf{y} - \mathbf{X}\hat{\boldsymbol{\beta}})'(\mathbf{y} - \mathbf{X}\hat{\boldsymbol{\beta}})$$

Aplicando transpuesta de una resta y producto ($(A - B)' = A' - B'$ y $(AB)' = B'A'$):
$$S(\hat{\boldsymbol{\beta}}) = (\mathbf{y}' - \hat{\boldsymbol{\beta}}'\mathbf{X}')(\mathbf{y} - \mathbf{X}\hat{\boldsymbol{\beta}})$$
$$S(\hat{\boldsymbol{\beta}}) = \mathbf{y}'\mathbf{y} - \mathbf{y}'\mathbf{X}\hat{\boldsymbol{\beta}} - \hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{y} + \hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{X}\hat{\boldsymbol{\beta}}$$

Dado que el producto $\mathbf{y}'\mathbf{X}\hat{\boldsymbol{\beta}}$ es un escalar ($1 \times 1$), es idéntico a su transpuesta ($\mathbf{y}'\mathbf{X}\hat{\boldsymbol{\beta}} = \hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{y}$), permitiendo agrupar:
$$S(\hat{\boldsymbol{\beta}}) = \mathbf{y}'\mathbf{y} - 2\hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{y} + \hat{\boldsymbol{\beta}}'\mathbf{X}'\mathbf{X}\hat{\boldsymbol{\beta}}$$

### Paso 3: Condición de Primer Orden (CPO)
Derivando vectorialmente con respecto a $\hat{\boldsymbol{\beta}}$ e igualando al vector nulo:
$$\frac{\partial S}{\partial \hat{\boldsymbol{\beta}}} = -2\mathbf{X}'\mathbf{y} + 2\mathbf{X}'\mathbf{X}\hat{\boldsymbol{\beta}} = \mathbf{0}$$

Dividiendo entre 2 y reordenando, obtenemos el célebre **Sistema de Ecuaciones Normales de Gauss**:
$$\mathbf{X}'\mathbf{X}\hat{\boldsymbol{\beta}} = \mathbf{X}'\mathbf{y}$$

### Paso 4: Despeje y Solución Analítica Cerrada
Dado que en álgebra matricial no existe la división, multiplicamos por la izquierda por la matriz inversa $(\mathbf{X}'\mathbf{X})^{-1}$:
$$(\mathbf{X}'\mathbf{X})^{-1}(\mathbf{X}'\mathbf{X})\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}$$
$$\mathbf{I}_k \hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}$$
$$\mathbf{\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}}$$

> **Propiedad Esencial:** Esta es una solución analítica exacta (*closed-form*), determinista y resoluble en un solo paso algebraico, sin recurrir a iteraciones heurísticas.

---

## 3. VALORES AJUSTADOS, MATRIZ HAT ($\mathbf{H}$) Y RESIDUOS ESTIMADOS ($\hat{\mathbf{u}}$)

### 3.1 Valores Ajustados ($\hat{\mathbf{y}}$) y Matriz de Proyección ($\mathbf{H}$)
Sustituyendo el estimador en el modelo ajustado:
$$\hat{\mathbf{y}} = \mathbf{X}\hat{\boldsymbol{\beta}} = \mathbf{X}(\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}$$

Se define la **Matriz Hat o de Proyección ($\mathbf{H}$)** de dimensión $n \times n$:
$$\mathbf{H} = \mathbf{X}(\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}' \quad \Longrightarrow \quad \hat{\mathbf{y}} = \mathbf{H}\mathbf{y}$$

**Propiedades de $\mathbf{H}$:**
1. **Simétrica:** $\mathbf{H}' = \mathbf{H}$.
2. **Idempotente:** $\mathbf{H}\mathbf{H} = \mathbf{H}$ (proyectar sobre un espacio ya proyectado no altera las coordenadas).
3. **Traza:** $\text{tr}(\mathbf{H}) = \text{rango}(\mathbf{X}) = k$ (la suma de su diagonal principal es igual al número total de parámetros).
4. **Apalancamiento (*Leverage*):** Los elementos diagonales $h_{ii}$ miden la distancia de cada observación al centroide de $\mathbf{X}$ y su potencial influencia sobre la recta ajustada.

### 3.2 Residuos Estimados ($\hat{\mathbf{u}}$) y Matriz Aniquiladora ($\mathbf{M}$)
El residuo representa la distancia perpendicular entre el dato observado y el hiperplano ajustado:
$$\hat{\mathbf{u}} = \mathbf{y} - \hat{\mathbf{y}} = \mathbf{y} - \mathbf{H}\mathbf{y} = (\mathbf{I}_n - \mathbf{H})\mathbf{y}$$

Definiendo $\mathbf{M} = \mathbf{I}_n - \mathbf{H}$ (Matriz generadora de residuos o aniquiladora):
$$\hat{\mathbf{u}} = \mathbf{M}\mathbf{y}$$

**Propiedades de $\mathbf{M}$:**
1. **Simétrica e Idempotente:** $\mathbf{M}' = \mathbf{M}$ y $\mathbf{M}\mathbf{M} = \mathbf{M}$.
2. **Traza:** $\text{tr}(\mathbf{M}) = \text{tr}(\mathbf{I}_n) - \text{tr}(\mathbf{H}) = n - k$ (coincide exactamente con los **grados de libertad residuales**).
3. **Ortogonalidad Fundamental:** $\mathbf{X}'\hat{\mathbf{u}} = \mathbf{X}'\mathbf{M}\mathbf{y} = \mathbf{0}$. Los residuos son estrictamente perpendiculares al espacio generado por las columnas explicativas de $\mathbf{X}$.
4. **Suma Cero:** Al incluir término independiente $\beta_0$, la primera fila de $\mathbf{X}'\hat{\mathbf{u}} = \mathbf{0}$ garantiza que $\sum_{i=1}^n \hat{u}_i = 0$.

---

## 4. INFERENCIA ESTADÍSTICA: DE $(\mathbf{X}'\mathbf{X})^{-1}$ A LA PRUEBA $t$

Bajo los supuestos clásicos de Gauss-Markov ($\mathbb{E}[\mathbf{u}|\mathbf{X}] = \mathbf{0}$ y $\text{Var}(\mathbf{u}|\mathbf{X}) = \sigma^2 \mathbf{I}_n$):

$$\text{Var}(\hat{\boldsymbol{\beta}}) = \sigma^2 (\mathbf{X}'\mathbf{X})^{-1}$$

Dado que $\sigma^2$ es desconocido, se estima insesgadamente mediante la varianza muestral del error $s^2$:
$$s^2 = \frac{\hat{\mathbf{u}}'\hat{\mathbf{u}}}{n - k}$$

La matriz de varianza-covarianza estimada es:
$$\widehat{\text{Var}}(\hat{\boldsymbol{\beta}}) = s^2 (\mathbf{X}'\mathbf{X})^{-1}$$

* **Error Estándar ($SE$):** Es la raíz cuadrada del elemento diagonal correspondiente:
  $$SE(\hat{\beta}_j) = \sqrt{[\widehat{\text{Var}}(\hat{\boldsymbol{\beta}})]_{jj}}$$
* **Estadístico $t$ de Student:** Evalúa la significancia individual ($H_0: \beta_j = 0$ frente a $H_1: \beta_j \neq 0$):
  $$t = \frac{\hat{\beta}_j}{SE(\hat{\beta}_j)}$$

---

## 5. RESOLUCIÓN PASO A PASO DEL EJEMPLO DIDÁCTICO MANUAL

Para ilustrar de forma numérica y reproducible la mecánica completa, se resuelve el caso pedagógico de muestra reducida:
* **Muestra:** $n = 3$ tiendas comerciales.
* **Variables:** $x_1$ = Inversión publicitaria (en miles USD), $y$ = Ventas generadas (en miles USD).
* **Parámetros:** $k = 2$ ($\beta_0$ e $\beta_1$).

### Datos del Ejemplo:
* Tienda 1: $x_{11} = 1$, $y_1 = 5$
* Tienda 2: $x_{21} = 2$, $y_2 = 7$
* Tienda 3: $x_{31} = 3$, $y_3 = 9$

### Paso 1: Configuración Matricial
$$\mathbf{y} = \begin{pmatrix} 5 \\ 7 \\ 9 \end{pmatrix}, \quad 
\mathbf{X} = \begin{pmatrix} 1 & 1 \\ 1 & 2 \\ 1 & 3 \end{pmatrix}, \quad 
\mathbf{X}' = \begin{pmatrix} 1 & 1 & 1 \\ 1 & 2 & 3 \end{pmatrix}$$

### Paso 2: Cálculo de la Matriz de Momentos $\mathbf{X}'\mathbf{X}$
$$\mathbf{X}'\mathbf{X} = \begin{pmatrix} 1 & 1 & 1 \\ 1 & 2 & 3 \end{pmatrix} \begin{pmatrix} 1 & 1 \\ 1 & 2 \\ 1 & 3 \end{pmatrix} = 
\begin{pmatrix} 1+1+1 & 1+2+3 \\ 1+2+3 & 1^2+2^2+3^2 \end{pmatrix} = \begin{pmatrix} 3 & 6 \\ 6 & 14 \end{pmatrix}$$

### Paso 3: Cálculo del Vector de Covariación $\mathbf{X}'\mathbf{y}$
$$\mathbf{X}'\mathbf{y} = \begin{pmatrix} 1 & 1 & 1 \\ 1 & 2 & 3 \end{pmatrix} \begin{pmatrix} 5 \\ 7 \\ 9 \end{pmatrix} = 
\begin{pmatrix} 5 + 7 + 9 \\ 1(5) + 2(7) + 3(9) \end{pmatrix} = \begin{pmatrix} 21 \\ 46 \end{pmatrix}$$

### Paso 4: Inversión de $\mathbf{X}'\mathbf{X}$
Determinante de la matriz $2 \times 2$:
$$\det(\mathbf{X}'\mathbf{X}) = (3)(14) - (6)(6) = 42 - 36 = 6 \neq 0 \quad (\text{No singular})$$

Fórmula de inversión analítica:
$$(\mathbf{X}'\mathbf{X})^{-1} = \frac{1}{6} \begin{pmatrix} 14 & -6 \\ -6 & 3 \end{pmatrix}$$

### Paso 5: Estimación del Vector $\hat{\boldsymbol{\beta}}$
$$\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y} = \frac{1}{6} \begin{pmatrix} 14 & -6 \\ -6 & 3 \end{pmatrix} \begin{pmatrix} 21 \\ 46 \end{pmatrix}$$
$$\hat{\boldsymbol{\beta}} = \frac{1}{6} \begin{pmatrix} 14(21) - 6(46) \\ -6(21) + 3(46) \end{pmatrix} = \frac{1}{6} \begin{pmatrix} 294 - 276 \\ -126 + 138 \end{pmatrix} = \frac{1}{6} \begin{pmatrix} 18 \\ 12 \end{pmatrix} = \begin{pmatrix} 3 \\ 2 \end{pmatrix}$$

**Ecuación Estimada:**
$$\hat{y}_i = 3 + 2x_{i1}$$

* **Interpretación:**
  * $\hat{\beta}_0 = 3$: Ventas mínimas esperadas en ausencia de publicidad ($x_1 = 0$) son $3,000$ USD.
  * $\hat{\beta}_1 = 2$: Por cada $1,000$ USD invertidos en publicidad, las ventas crecen en promedio $2,000$ USD.

### Paso 6: Verificación de Valores Ajustados y Residuos
* Para $x_1 = 1 \implies \hat{y}_1 = 3 + 2(1) = 5 \implies \hat{u}_1 = y_1 - \hat{y}_1 = 5 - 5 = 0$.
* Para $x_2 = 2 \implies \hat{y}_2 = 3 + 2(2) = 7 \implies \hat{u}_2 = y_2 - \hat{y}_2 = 7 - 7 = 0$.
* Para $x_3 = 3 \implies \hat{y}_3 = 3 + 2(3) = 9 \implies \hat{u}_3 = y_3 - \hat{y}_3 = 9 - 9 = 0$.

Se comprueba la suma nula de residuos ($\sum \hat{u}_i = 0$) y el ajuste perfecto $R^2 = 1.0$ de este caso didáctico.
