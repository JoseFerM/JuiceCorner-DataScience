# Modelización Empresarial I (Econometría MCO) — Bases y Avance (Fase 4 / OE4–OE5)

**Estado:** Completada (100 %)  
**Objetivos vinculados:** **OE4** (estimar sensibilidad de demanda y umbral de quiebre) y **OE5** (simular escenarios de asignación promocional).

---

## 1. Fundamentos Teóricos (Bases)

1. **Formulación Matricial del Modelo Lineal:**
   $$\mathbf{y} = \mathbf{X}\boldsymbol{\beta} + \mathbf{u}, \qquad \hat{\boldsymbol{\beta}} = (\mathbf{X}^\top \mathbf{X})^{-1}\mathbf{X}^\top \mathbf{y}$$
   donde $\mathbf{y}_{(19\,440 \times 1)}$ es el vector de demanda logarítmica y $\mathbf{X}_{(19\,440 \times 7)}$ la matriz de diseño.
2. **Especificación Log-Lineal de Demanda con Efectos Fijos:**
   $$\ln(Q_{it}) = \beta_0 + \beta_1 \ln(P_{it}) + \beta_2 D_{it} + \beta_3 \text{Desc}_{it} + \delta_1 \text{Delivery}_{it} + \gamma_1 \text{Sucursal}_2 + \gamma_2 \text{Sucursal}_3 + u_{it}$$
   - $\beta_1$: elasticidad-precio directa de la demanda.
   - $\beta_2, \beta_3$: semielasticidades frente a descuento de línea (%) y cupón prorrateado (%).
   - $\delta_1$: diferencial de volumen del canal `delivery` frente a `dine_in`.
   - $\gamma_1, \gamma_2$: efectos fijos territoriales (Banani y Gulshan vs. referencia Dhanmondi).
3. **Validación de Supuestos Clásicos y Robustez:**
   - **Normalidad:** Jarque-Bera y respaldo asintótico por Teorema del Límite Central ($N = 19.440$).
   - **Heterocedasticidad:** Test de Breusch-Pagan y corrección mediante matriz de covarianzas robusta **White HC1**.
   - **Multicolinealidad:** Factor de Inflación de Varianza (**VIF** $< 5$).

---

## 2. Resultados Consolidados

- **Panel balanceado:** 19.440 observaciones (20 productos $\times$ 162 días $\times$ 3 sucursales $\times$ 2 canales) en [`../../resultados_modelizacion/dataset_regresion_mco.csv`](../../resultados_modelizacion/dataset_regresion_mco.csv).
- **Ajuste global:** $R^2 = 0.369$ ($R^2_{\text{adj}} = 0.369$), $F = 1.896$ ($p < 0.001$).
- **Elasticidad-precio ($\beta_1 = -0.0792$, $p < 0.001$):** Demanda altamente inelástica ($|\beta_1| \ll 1$); recortar descuentos no provoca caídas significativas de volumen.
- **Ineficacia del descuento de línea ($\beta_2 = +0.0006$, $p = 0.004$):** Impacto marginal prácticamente nulo sobre unidades vendidas.
- **Efecto de cupones ($\beta_3 = -0.0113$, $p < 0.001$):** Efecto neto negativo sobre la dinámica comercial y erosión directa de margen.
- **Motor delivery ($\delta_1 = +0.2009$, $p < 0.001$):** $+22,3\%$ más volumen frente a salón (`dine_in`).
- **Homogeneidad territorial ($\gamma_1 = -0.0028, p = 0.227$; $\gamma_2 = -0.0023, p = 0.323$):** No hay diferencias significativas entre sucursales.
- **Diagnósticos:** Breusch-Pagan ($p = 0.014$) corregido con White HC1; VIF máximo $= 2.73 < 5$.
- **Simulación de Escenarios y Sensibilidad:**
  - **E1 (Línea Base):** 7,24 % costo descuentos (78,84M BDT), margen 58,64 % (638,57M BDT).
  - **E2 (Reasignación Moderada):** 2,24 % costo descuentos (25,54M BDT), margen 61,25 % (691,87M BDT), ahorro **+53,30M BDT**.
  - **Umbral de quiebre:** La demanda tendría que caer más de **7,70 %** (384.644 unidades) para anular el beneficio de E2.

---

## 3. Documentos y Artefactos en esta Carpeta

- [`Documento_A_Analisis_Ejemplo_Guia_MCO.md`](Documento_A_Analisis_Ejemplo_Guia_MCO.md)
- [`Documento_B_Aplicacion_Proyecto_Integrador_MCO.md`](Documento_B_Aplicacion_Proyecto_Integrador_MCO.md)
- [`Guia_Estudio_Enfoque_Matricial_MCO.md`](Guia_Estudio_Enfoque_Matricial_MCO.md) y [`Guia_Estudio_Matricial_MCO.docx`](Guia_Estudio_Matricial_MCO.docx)
- [`Identificacion_DW_y_Estimacion_Matricial_MCO.md`](Identificacion_DW_y_Estimacion_Matricial_MCO.md)
- Scripts y reportes en raíz: [`modelizacion_mco.py`](../../modelizacion_mco.py), [`ejecucion_matricial_y_statsmodels.py`](../../ejecucion_matricial_y_statsmodels.py), [`reporte_modelizacion_mco.html`](../../reporte_modelizacion_mco.html), [`guia_estudio_matricial_mco.html`](../../guia_estudio_matricial_mco.html).
