# IDENTIFICACIÓN DE TABLAS DEL DATA WAREHOUSE Y ESTIMACIÓN MATRICIAL MCO
**Proyecto:** Juice Corner BD — Sistema TPS y Data Warehouse  
**Asignatura:** Modelización Empresarial I  
**Institución:** Universidad del Valle (UNIVALLE) — LCD 4to Semestre  
**Docente:** MSc. Karen G. Meneses M.  

---

## 1. ESPECIFICACIÓN DEL MODELO ECONOMÉTRICO
El modelo sugerido por la docente estima la demanda de productos de Juice Corner mediante una ecuación log-lineal con efectos fijos de canal y sucursal:

$$\ln(Q_{it}) = \beta_0 + \beta_1 \ln(P_{it}) + \beta_2 D_{it} + \beta_3 \text{Desc}_{it} + \delta_1 \text{Delivery}_{it} + \gamma_1 \text{Sucursal}_2 + \gamma_2 \text{Sucursal}_3 + u_{it}$$

### Formulación Matricial Universal
$$\mathbf{y} = \mathbf{X}\boldsymbol{\beta} + \mathbf{u}$$

Donde:
* $\mathbf{y}$ es el vector columna de observaciones de la variable dependiente de dimensión $(n \times 1) = (19,440 \times 1)$.
* $\mathbf{X}$ es la matriz de diseño de regresores de dimensión $(n \times k) = (19,440 \times 7)$.
* $\boldsymbol{\beta}$ es el vector de parámetros a estimar de dimensión $(k \times 1) = (7 \times 1)$.
* $\mathbf{u}$ es el vector de perturbaciones aleatorias inobservadas de dimensión $(n \times 1) = (19,440 \times 1)$.

---

## 2. MAPEO DIMENSIONAL DEL DATA WAREHOUSE AL MODELO

### A. Alimentación del Vector Dependiente $\mathbf{y}$
* **Tabla de Hechos Central:** `dbo.FACT_VENTAS`
  * **Medida Base:** `quantity` (unidades vendidas en cada línea de pedido, grano `order_items.id`).
  * **Agregación Panel:** $\sum \text{quantity} = Q_{it}$, sobre el cual se calcula $\ln(Q_{it})$.
* **Dimensiones que determinan el grano del corte ($producto \times tiempo \times sucursal \times canal$):**
  1. `dbo.DIM_PRODUCTO`: Clave `producto_key` (20 productos analizados).
  2. `dbo.DIM_TIEMPO`: Clave `tiempo_key` (162 días registrados).
  3. `dbo.DIM_SUCURSAL`: Clave `sucursal_key` (3 sucursales operativas).
  4. Atributo Degenerado `tipo_pedido` en `FACT_VENTAS`: 2 canales de venta (`dine_in` vs. `delivery`).

$$n = 20 \times 162 \times 3 \times 2 = 19,440 \text{ observaciones}$$

### B. Alimentación de Cada Columna de la Matriz $\mathbf{X}$
| Columna | Variable | Parámetro | Origen en DW (`JuiceCorner_DW`) | Campo y Operación |
| :---: | :--- | :---: | :--- | :--- |
| **1** | Constante ($\mathbf{1}$) | $\beta_0$ | Vector constante de Unos | Columna escalar $1.0$ generada para enganchar el intercepto. |
| **2** | $\ln(P_{it})$ | $\beta_1$ | `dbo.FACT_VENTAS` + `dbo.DIM_PRODUCTO` | Campo `unit_price` promediado en el corte panel y transformado a $\ln(P_{it})$. |
| **3** | $D_{it}$ | $\beta_2$ | `dbo.FACT_VENTAS` | Medidas `descuento_linea`, `unit_price` y `quantity`: $(\text{descuento\_linea} / (\text{unit\_price} \times \text{quantity})) \times 100$. |
| **4** | $\text{Desc}_{it}$ | $\beta_3$ | `dbo.FACT_VENTAS` | Medidas `descuento_cupon_prorr` y `subtotal`: $(\text{descuento\_cupon\_prorr} / \text{subtotal}) \times 100$. |
| **5** | $\text{Delivery}_{it}$ | $\delta_1$ | `dbo.FACT_VENTAS` (`tipo_pedido`) | Atributo degenerado: $1$ si `tipo_pedido = 'delivery'`, $0$ si `tipo_pedido = 'dine_in'`. |
| **6** | $\text{Sucursal}_2$ | $\gamma_1$ | `dbo.DIM_SUCURSAL` (vía `sucursal_key`) | Clave natural `branch_id_nk = 2` (Gulshan): $1$ si es Gulshan, $0$ en otro caso. |
| **7** | $\text{Sucursal}_3$ | $\gamma_2$ | `dbo.DIM_SUCURSAL` (vía `sucursal_key`) | Clave natural `branch_id_nk = 3` (Banani): $1$ si es Banani, $0$ en otro caso. |

---

## 3. DEFINICIÓN DE CATEGORÍAS BASE Y PREVENCIÓN DE SINGULARIDAD EN $\mathbf{X}'\mathbf{X}$

### Demostración de la Trampa de las Variables Ficticias (*Dummy Variable Trap*)
Para que exista la solución analítica cerrada de MCO:
$$\hat{\boldsymbol{\beta}} = (\mathbf{X}'\mathbf{X})^{-1}\mathbf{X}'\mathbf{y}$$
la matriz $\mathbf{X}'\mathbf{X}$ debe ser invertible ($\det(\mathbf{X}'\mathbf{X}) \neq 0$). 

Si para una variable cualitativa con $m$ categorías se incluyeran $m$ variables dicotómicas además del intercepto:
$$\sum_{j=1}^m D_{ij} = \mathbf{1} = x_{i0}$$
La suma de las columnas dummies sería idéntica a la primera columna de unos de $\mathbf{X}$. Como resultado:
1. Las columnas de $\mathbf{X}$ son linealmente dependientes.
2. $\text{rango}(\mathbf{X}) < k = 7$.
3. $\det(\mathbf{X}'\mathbf{X}) = 0$, lo que convierte a $\mathbf{X}'\mathbf{X}$ en una matriz **singular (no invertible)**.
4. El estimador MCO no puede calcularse.

### Categorías Base Seleccionadas
Para garantizar que $\mathbf{X}'\mathbf{X}$ tenga rango completo ($r = 7$) y sea invertible:
1. **Canal de Venta ($m = 2$):**
   * Categorías: `delivery` y `dine_in`.
   * Dummy incluida: $\text{Delivery}_{it}$.
   * **Categoría Base (Omitida):** **`dine_in` (Consumo en Salón)**.
2. **Sucursales ($m = 3$):**
   * Categorías: Dhanmondi (1), Gulshan (2), Banani (3).
   * Dummies incluidas: $\text{Sucursal}_2$ (Gulshan) y $\text{Sucursal}_3$ (Banani).
   * **Categoría Base (Omitida):** **Sucursal 1: Dhanmondi (Sede Central / Casa Matriz)**.

El intercepto $\beta_0$ absorbe la demanda esperada de la categoría base de referencia conjunta: producto vendido en **Salón** en la sucursal matriz de **Dhanmondi**.
