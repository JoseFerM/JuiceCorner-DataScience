# Estadística e Inferencia — Bases y Avance (Fase 3 / OE3)

**Estado:** Completada (100 %)  
**Objetivo vinculado:** **OE3** — Contrastar estadísticamente la homogeneidad de la demanda diaria y la correlación existente entre la tasa de descuento otorgada y el margen a precio de lista ($\alpha = 0,05$).

---

## 1. Fundamentos Teóricos (Bases)

1. **Pruebas de Homogeneidad de Demanda (Multi-grupo):**
   - **ANOVA de un factor ($F$):** Evalúa si las medias diarias/totales de unidades vendidas difieren significativamente entre los 20 productos del menú ($H_{0,2}: \mu_1 = \mu_2 = \dots = \mu_{20}$).
   - **Prueba no paramétrica de Kruskal-Wallis:** Validación robusta ante posibles desviaciones de normalidad en las distribuciones de venta por ítem.
   - **Coeficiente de Variación (CV):** Mide la dispersión relativa de la participación de cada producto en el mix total.
2. **Asociación Categórica e Independencia:**
   - **Coeficiente $V$ de Cramér:** Cuantifica el grado de asociación entre la composición del mix de productos y variables categóricas de segmentación (sucursal, canal `dine_in` / `delivery` y fecha).
3. **Correlación Descuento–Margen:**
   - **Coeficiente de Correlación de Pearson ($r$):** Evalúa si la política histórica de descuentos premia a los productos más rentables ($r > 0$) o está desalineada ($r \le 0$).
4. **Auditoría Estadística de Reglas Promocionales:**
   - Evaluación de tasas de incumplimiento en redención de cupones (vigencia temporal y montos mínimos de compra).

---

## 2. Resultados Consolidados (Evidencia Empírica)

- **Universo auditado:** 1.000.000 de órdenes transaccionales, 2.498.660 líneas de detalle y 4.995.377 unidades físicas vendidas.
- **Homogeneidad de la Demanda ($H_{0,2}$ no rechazada):**
  - ANOVA: $F = 0,695$ ($p = 0,819 > 0,05$).
  - Kruskal-Wallis: $p = 0,908 > 0,05$.
  - Participación uniforme: ~5 % de la mezcla por cada uno de los 20 productos ($\text{CV} = 0,26\,\%$).
  - Independencia estructural: $V$ de Cramér entre $0,0025$ y $0,0077$ (la mezcla de productos no depende de sucursal, canal ni fecha).
- **Desalineación Descuento–Margen:**
  - Correlación de Pearson: $r = -0,19$ ($p = 0,415$), evidenciando una relación negativa y estadísticamente no alineada con la rentabilidad.
  - *Caso extremo:* *Blue Lagoon Mocktail* (94,2 % de margen) recibe 11,1 % de descuento, mientras *Strawberry Cream Shake* (14,4 % de margen) no recibe beneficio alguno.
  - 7 productos con margen $< 70\,\%$ absorben **42,4 millones de BDT** (81 % del descuento de línea y 54 % del costo promocional total).
- **Infracción en Cupones:**
  - 38,65 % de las órdenes usan cupón.
  - `EID50`: 94,4 % de sus usos ocurrieron fuera de vigencia.
  - `VIP100`: 18,7 % de sus usos se aplicaron por debajo del monto mínimo.

---

## 3. Avance y Entregables

- [x] Análisis inferencial completo ejecutado en R y documentado en [`../00_Proyecto_Integrador/Avance.docx`](../00_Proyecto_Integrador/Avance.docx) y [`../00_Proyecto_Integrador/Avance_Adaptado_Capitulo_I.md`](../00_Proyecto_Integrador/Avance_Adaptado_Capitulo_I.md).
- [x] Figuras de soporte generadas en [`../img/figura3_unidades.png`](../img/figura3_unidades.png), [`../img/figura4_margen.png`](../img/figura4_margen.png) y [`../img/figura5_dispersion.png`](../img/figura5_dispersion.png).
- [x] Insumos estadísticos validados como línea base para la Fase 4 (Modelización MCO) y Fase 5 (Optimización LP).
