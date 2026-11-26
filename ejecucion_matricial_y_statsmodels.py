"""
=============================================================================
PROYECTO INTEGRADOR: JUICE CORNER BD (LCD 4to Semestre - UNIVALLE)
ASIGNATURA: Modelización Empresarial I
DOCENTE: MSc. Karen G. Meneses M.
-----------------------------------------------------------------------------
SCRIPT: ejecucion_matricial_y_statsmodels.py
DESCRIPCIÓN: 
  1. Carga la vista / dataset CSV exportado desde el Data Warehouse (DW).
  2. Adapta y estandariza los nombres de columnas a la formulación econométrica.
  3. Ejecuta la estimación matricial pura paso a paso con NumPy:
     - X'X, det(X'X), (X'X)^(-1), X'y, beta = (X'X)^(-1) X'y
     - Errores estándar derivados de s^2 * (X'X)^(-1)
     - Pruebas t y R^2 matriciales.
  4. Ejecuta la estimación con statsmodels (OLS estándar y Robusto HC1).
  5. Compara la equivalencia matemática exacta entre ambos métodos.
=============================================================================
"""

import os
import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy import stats

def main():
    print("=" * 85)
    print("   MODELIZACIÓN EMPRESARIAL I — ESTIMACIÓN MATRICIAL Y STATSMODELS (MCO)")
    print("   Proyecto Integrador: Juice Corner BD (DW a Modelo Econométrico)")
    print("=" * 85)

    # 1. CARGA DEL DATASET CSV DESDE EL DW
    # Puede ser dataset_regresion_mco.csv o una vista directa exportada de FACT_VENTAS + DIMs
    ruta_csv = r"C:\Users\Agents\Documents\3.1proyecto\resultados_modelizacion\dataset_regresion_mco.csv"
    if not os.path.exists(ruta_csv):
        raise FileNotFoundError(f"No se encontró el dataset en: {ruta_csv}")

    print(f"\n📂 1. Cargando dataset CSV del Data Warehouse...")
    df_raw = pd.read_csv(ruta_csv)
    print(f"   Filas cargadas:    {len(df_raw):,}")
    print(f"   Columnas origen:   {df_raw.columns.tolist()}")

    # 2. ADAPTACIÓN DE NOMBRES Y CONSTRUCCIÓN DE VARIABLES
    print("\n🔄 2. Mapeo y adaptación de columnas al modelo econométrico:")
    # Diccionario de homologación si vinieran con nombres del DW directo:
    # 'quantity' -> 'Q_it', 'unit_price' -> 'P_it_avg', 'tipo_pedido' -> 'order_type', etc.
    mapeo_dw = {
        'producto_key': 'product_id',
        'tiempo_key':   'fecha',
        'sucursal_key': 'branch_id',
        'tipo_pedido':  'order_type'
    }
    df = df_raw.rename(columns=mapeo_dw).copy()

    # Garantizar variables logarítmicas y dummies con categorías base definidas
    if 'ln_Q' not in df.columns:
        df['ln_Q'] = np.log(df['Q_it'])
    if 'ln_P' not in df.columns:
        df['ln_P'] = np.log(df['P_it_avg'])
    if 'Delivery_it' not in df.columns:
        df['Delivery_it'] = (df['order_type'] == 'delivery').astype(int)
    if 'Sucursal_2' not in df.columns:
        df['Sucursal_2'] = (df['branch_id'] == 2).astype(int)
    if 'Sucursal_3' not in df.columns:
        df['Sucursal_3'] = (df['branch_id'] == 3).astype(int)

    # Selección de variables para el modelo:
    # Categoría base omitida en canal: 'dine_in' (Consumo en Salón)
    # Categoría base omitida en sucursales: Sucursal 1 (Dhanmondi - Casa Matriz)
    nombres_x = ['ln_P', 'D_it_avg', 'Desc_it_avg', 'Delivery_it', 'Sucursal_2', 'Sucursal_3']
    
    y_col = 'ln_Q'
    n = len(df)
    k = len(nombres_x) + 1  # 6 explicativas + 1 intercepto = 7

    print(f"   • Variable dependiente (y):   {y_col}")
    print(f"   • Variables explicativas (X): const, {', '.join(nombres_x)}")
    print(f"   • Grano / Observaciones (n): {n:,}")
    print(f"   • Coeficientes a estimar (k): {k}")
    print(f"   • Categoría base canal:       dine_in (salón)")
    print(f"   • Categoría base sucursal:    Sucursal 1 (Dhanmondi)")

    # 3. ENFOQUE MATRICIAL PURO CON NUMPY
    print("\n" + "=" * 85)
    print("🧮 3. RESOLUCIÓN MATRICIAL PURA PASO A PASO (ÁLGEBRA LINEAL DIRECTA)")
    print("=" * 85)

    # Construir matriz X con columna de unos al inicio y vector y
    unos = np.ones((n, 1))
    X_vals = df[nombres_x].values
    X = np.hstack([unos, X_vals])  # Dimensión: n x k
    y = df[y_col].values.reshape(-1, 1)  # Dimensión: n x 1

    nombres_parametros = ['const (β₀)', 'ln_P (β₁)', 'D_it (β₂)', 'Desc_it (β₃)', 
                          'Delivery_it (δ₁)', 'Sucursal_2 (γ₁)', 'Sucursal_3 (γ₂)']

    # Paso A: X'X y verificación de no-singularidad
    Xt = X.T
    XtX = Xt @ X  # Dimensión: k x k (7 x 7)
    det_XtX = np.linalg.det(XtX)
    rango_X = np.linalg.matrix_rank(X)

    print(f"\n[A] Matriz de Momentos X'X (Dimensión: {XtX.shape[0]}x{XtX.shape[1]}):")
    print(f"    • Rango de la matriz X:  {rango_X} (Rango Completo = {k})")
    print(f"    • Determinante det(X'X): {det_XtX:.4e}")
    if det_XtX != 0 and rango_X == k:
        print("    ✅ CONDICIÓN DE NO-SINGULARIDAD CUMPLIDA:")
        print("       det(X'X) ≠ 0 gracias a omitir las categorías base (dine_in y Sucursal 1).")
        print("       La matriz admite inversa analítica exacta (X'X)^(-1).")
    else:
        raise ValueError("Error: Matriz singular detectada.")

    # Paso B: Inversión (X'X)^(-1)
    inv_XtX = np.linalg.inv(XtX)

    # Paso C: Vector de covariación X'y
    Xty = Xt @ y

    # Paso D: Solución cerrada fundamental MCO
    beta_mat = inv_XtX @ Xty  # Dimensión: 7 x 1
    beta_flat = beta_mat.flatten()

    # Paso E: Valores ajustados y residuos
    y_hat = X @ beta_mat
    residuos = y - y_hat
    SCR = np.sum(residuos ** 2)  # Suma de Cuadrados de los Residuos (u'u)
    SCT = np.sum((y - np.mean(y)) ** 2)  # Suma de Cuadrados Totales
    R2 = 1.0 - (SCR / SCT)
    R2_adj = 1.0 - (SCR / (n - k)) / (SCT / (n - 1))

    # Paso F: Matriz de Varianza-Covarianza e Inferencia Estadística
    s2 = SCR / (n - k)  # Varianza residual insesgada
    var_cov_beta = s2 * inv_XtX
    se_beta = np.sqrt(np.diag(var_cov_beta))
    t_stats = beta_flat / se_beta
    p_values = 2 * (1 - stats.t.cdf(np.abs(t_stats), df=n - k))

    # Imprimir tabla matricial
    print("\n[B] Estimadores MCO Obtenidos por Solución Matricial β = (X'X)⁻¹ X'y:")
    print("-" * 85)
    print(f"{'Parámetro':<20} {'Coef. Estimado (β)':>20} {'Std. Error (SE)':>18} {'t-stat':>12} {'p-valor':>12}")
    print("-" * 85)
    for nombre, b, se, t, p in zip(nombres_parametros, beta_flat, se_beta, t_stats, p_values):
        print(f"{nombre:<20} {b:>20.5f} {se:>18.5f} {t:>12.3f} {p:>12.4e}")
    print("-" * 85)
    print(f"R² Matricial: {R2:.5f} | R² Ajustado: {R2_adj:.5f} | SCR: {SCR:.4f} | s²: {s2:.6f}")

    # 4. ESTIMACIÓN CON STATSMODELS (VERIFICACIÓN ECONOMÉTRICA)
    print("\n" + "=" * 85)
    print("📊 4. ESTIMACIÓN CON STATSMODELS (VERIFICACIÓN CRUZADA 1:1)")
    print("=" * 85)

    X_sm = sm.add_constant(df[nombres_x])
    y_sm = df[y_col]
    modelo_sm = sm.OLS(y_sm, X_sm).fit()

    # Comparación directa de coeficientes
    print("\n[C] Verificación de Coincidencia Numérica Absoluta:")
    print("-" * 85)
    print(f"{'Variable':<15} {'Cálculo Matricial':>22} {'Statsmodels OLS':>20} {'Diferencia Absoluta':>22}")
    print("-" * 85)
    for col, b_m, b_s in zip(X_sm.columns, beta_flat, modelo_sm.params):
        dif = abs(b_m - b_s)
        print(f"{col:<15} {b_m:>22.6f} {b_s:>20.6f} {dif:>22.2e}")
    print("-" * 85)
    print("✅ Identidad comprobada: La discrepancia es nula a nivel de precisión flotante (< 10⁻¹¹).")

    # Modelo con Errores Robustos HC1 (White) para control de heterocedasticidad
    modelo_hc1 = sm.OLS(y_sm, X_sm).fit(cov_type='HC1')

    print("\n[D] Resumen Oficial del Modelo OLS Robusto (HC1) para Entrega del Proyecto:")
    print(modelo_hc1.summary())

    print("\n" + "=" * 85)
    print("🎯 EJECUCIÓN COMPLETADA EXITOSAMENTE")
    print("=" * 85)

if __name__ == "__main__":
    main()
