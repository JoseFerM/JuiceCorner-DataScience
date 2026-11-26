# Optimización (Programación Lineal) — Bases y Avance (Fase 5 / OE5–OE6)

**Estado:** En Curso (Formulación definida; implementación en PuLP pendiente de ejecución final)  
**Objetivos vinculados:** **OE5** (simulación de escenario optimizado E3) y **OE6** (política definitiva de descuentos diferenciados).

---

## 1. Fundamentos Teóricos (Bases)

La optimización de la política de descuentos (**Escenario E3**) se plantea como un problema de **Programación Lineal (LP)** resuelto con la librería `PuLP` en Python, tomando como insumos los márgenes unitarios, volúmenes proyectados y elasticidades estimadas en la Fase 4.

### Formulación Matemática Base

- **Variables de decisión:**
  $$d_{i,c} \ge 0 \quad \text{Tasa de descuento asignada al producto } i \in \{1,\dots,20\} \text{ en el canal } c \in \{\text{dine\_in}, \text{delivery}\}$$

- **Función Objetivo (Maximizar el Margen de Contribución Global):**
  $$\max Z = \sum_{i=1}^{20} \sum_{c} \Big[ P_i \cdot (1 - d_{i,c}) - C_i \Big] \cdot Q_{i,c}$$
  donde $P_i$ es el precio de lista, $C_i$ el costo unitario (COGS) y $Q_{i,c}$ el volumen esperado.

- **Restricciones Principales:**
  1. **Techo de Presupuesto Promocional ($\le 5,00\%$ del subtotal neto):**
     $$\frac{\sum_{i,c} P_i \cdot d_{i,c} \cdot Q_{i,c}}{\sum_{i,c} P_i \cdot Q_{i,c}} \le 0,05$$
  2. **Piso de Margen de Contribución Global ($\ge 62,00\%$):**
     $$\frac{Z}{\sum_{i,c} P_i \cdot (1 - d_{i,c}) \cdot Q_{i,c}} \ge 0,62$$
  3. **Cotas Operativas por Margen del Producto:**
     - Productos con margen vulnerable ($< 50\,\%$): $d_{i,c} = 0$ (exclusión de subsidios).
     - Productos altamente rentables ($> 70\,\%$): $0 \le d_{i,c} \le d_{\max}$ (priorizando canal `delivery`).
  4. **Conservación de Carta y Volumen:** Sin eliminación de ítems ni variación de precios de lista.

---

## 2. Avance Actual y Próximos Pasos

- [x] **Línea base (E1) y reasignación heurística moderada (E2)** simuladas en [`modelizacion_mco.py`](../../modelizacion_mco.py) (`resumen_productos_e1.csv` y `resumen_productos_e2.csv`).
- [x] **Restricciones de elasticidad y sensibilidad** validadas ($\beta_1 = -0,0792$, umbral de quiebre $7,70\,\%$).
- [ ] **Implementación del script LP en `PuLP`** para obtener la matriz óptima exacta del **Escenario E3**.
- [ ] **Análisis dual / precios sombra** de las restricciones del 5,00 % y 62,00 % para el informe final.
- [ ] **Integración de resultados E3** en [`reporte_modelizacion_mco.html`](../../reporte_modelizacion_mco.html) y en el visualizador principal.
