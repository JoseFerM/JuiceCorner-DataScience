# =============================================================================
# MODELIZACIÓN EMPRESARIAL I — Modelo Econométrico MCO
# Proyecto Integrador 4to Semestre LCD — Grupo 1: Juice Corner BD
# =============================================================================
# Ecuación sugerida por la docente:
#   ln(Q_it) = β₀ + β₁·ln(P_it) + β₂·D_it + β₃·Desc_it
#              + δ₁·Delivery_it + Σγ_k·Sucursal_kt + u_it
#
# Estimación: Mínimos Cuadrados Ordinarios (MCO) en Python
# =============================================================================

import pandas as pd
import numpy as np
import statsmodels.api as sm
from statsmodels.stats.diagnostic import het_breuschpagan, het_white
from statsmodels.stats.stattools import durbin_watson
from scipy import stats
import warnings, os

warnings.filterwarnings('ignore')

# ─────────────────────────────────────────────────────────────────────────────
# 0. CONFIGURACIÓN DE RUTAS
# ─────────────────────────────────────────────────────────────────────────────
DATA = r'C:\Users\Agents\Documents\3.1proyecto\dataset'
OUT  = r'C:\Users\Agents\Documents\3.1proyecto\resultados_modelizacion'
os.makedirs(OUT, exist_ok=True)

print("=" * 80)
print("MODELIZACIÓN EMPRESARIAL I — MODELO ECONOMÉTRICO MCO")
print("Juice Corner BD — Elasticidad, Descuentos y Mezcla de Productos")
print("=" * 80)

# ─────────────────────────────────────────────────────────────────────────────
# 1. CARGA DE DATOS
# ─────────────────────────────────────────────────────────────────────────────
print("\n📂 Cargando datasets...")

orders      = pd.read_csv(f'{DATA}/orders.csv')
order_items = pd.read_csv(f'{DATA}/order_items.csv')
products    = pd.read_csv(f'{DATA}/products.csv')
coupons     = pd.read_csv(f'{DATA}/coupons.csv')
coupon_red  = pd.read_csv(f'{DATA}/coupon_redemptions.csv')
ingredients = pd.read_csv(f'{DATA}/ingredients.csv')
prod_ing    = pd.read_csv(f'{DATA}/product_ingredients.csv')
branches    = pd.read_csv(f'{DATA}/branches.csv')

print(f"   Órdenes:        {len(orders):>12,}")
print(f"   Líneas pedido:  {len(order_items):>12,}")
print(f"   Productos:      {len(products):>12,}")
print(f"   Ingredientes:   {len(ingredients):>12,}")

# ─────────────────────────────────────────────────────────────────────────────
# 2. CÁLCULO DEL COSTO UNITARIO POR PRODUCTO (desde ingredientes)
# ─────────────────────────────────────────────────────────────────────────────
print("\n💰 Calculando costo unitario por producto (receta de ingredientes)...")

# Unir product_ingredients con ingredients para obtener cost_per_unit
pi = prod_ing.merge(ingredients[['id', 'cost_per_unit']], 
                     left_on='ingredient_id', right_on='id', 
                     suffixes=('', '_ing'))

# Costo por ingrediente en la receta = quantity * cost_per_unit
pi['costo_ingrediente'] = pi['quantity'] * pi['cost_per_unit']

# Costo total unitario por producto = suma de costos de ingredientes
costo_producto = pi.groupby('product_id')['costo_ingrediente'].sum().reset_index()
costo_producto.columns = ['product_id', 'costo_unitario']

# Unir con productos
products = products.merge(costo_producto, left_on='id', right_on='product_id', how='left')
products['margen_unitario'] = products['price'] - products['costo_unitario']
products['margen_pct'] = (products['margen_unitario'] / products['price'] * 100).round(2)

# Tasa de descuento de lista (si tiene discounted_price)
products['desc_linea_pct'] = np.where(
    products['discounted_price'].notna(),
    ((products['price'] - products['discounted_price']) / products['price'] * 100).round(2),
    0.0
)

print("\n📊 Tabla de Productos con Costos y Márgenes:")
print("-" * 100)
print(f"{'ID':>3} {'Producto':<30} {'Precio':>8} {'Costo':>8} {'Margen':>8} {'Margen%':>8} {'Desc%':>7}")
print("-" * 100)
for _, p in products.iterrows():
    print(f"{p['id']:>3} {p['name']:<30} {p['price']:>8.0f} {p['costo_unitario']:>8.2f} "
          f"{p['margen_unitario']:>8.2f} {p['margen_pct']:>7.1f}% {p['desc_linea_pct']:>6.1f}%")

# ─────────────────────────────────────────────────────────────────────────────
# 3. CONSTRUCCIÓN DEL DATASET PARA REGRESIÓN
#    Nivel de agregación: producto × día × sucursal × canal
# ─────────────────────────────────────────────────────────────────────────────
print("\n🔧 Construyendo dataset de regresión (nivel: producto × día × sucursal × canal)...")

# Preparar campos de órdenes
orders['placed_at'] = pd.to_datetime(orders['placed_at'])
orders['fecha'] = orders['placed_at'].dt.date

# Unir order_items con orders
df = order_items.merge(
    orders[['id', 'branch_id', 'order_type', 'coupon_id', 'fecha',
            'subtotal', 'discount_amount', 'coupon_discount']],
    left_on='order_id', right_on='id', suffixes=('', '_order')
)

# Unir con productos para obtener precio de lista y costo
df = df.merge(
    products[['id', 'name', 'price', 'costo_unitario', 'margen_unitario', 'desc_linea_pct']],
    left_on='product_id', right_on='id', suffixes=('', '_prod')
)

# ── Variables del modelo ──

# D_it: Tasa de descuento de línea real aplicada (porcentaje)
df['D_it'] = (df['discount'] / (df['unit_price'] * df['quantity'])) * 100
df['D_it'] = df['D_it'].clip(0, 100)

# Desc_it: Intensidad del cupón sobre la orden (peso porcentual)
df['tiene_cupon'] = df['coupon_id'].notna().astype(int)
df['Desc_it'] = np.where(
    df['subtotal'] > 0,
    (df['coupon_discount'].fillna(0) / df['subtotal']) * 100,
    0
)

# Delivery_it: Variable dummy (1=delivery, 0=dine_in)
df['Delivery_it'] = (df['order_type'] == 'delivery').astype(int)

# Variables dummy de sucursal (base = sucursal 1 Dhanmondi)
df['Sucursal_2'] = (df['branch_id'] == 2).astype(int)  # Gulshan
df['Sucursal_3'] = (df['branch_id'] == 3).astype(int)  # Banani

# ── Agregación: producto × día × sucursal × canal ──
agg = df.groupby(['product_id', 'name', 'fecha', 'branch_id', 'order_type']).agg(
    Q_it       = ('quantity', 'sum'),          # Total unidades vendidas
    P_it_avg   = ('unit_price', 'mean'),       # Precio promedio efectivo
    D_it_avg   = ('D_it', 'mean'),             # Tasa de descuento promedio
    Desc_it_avg= ('Desc_it', 'mean'),          # Intensidad de cupón promedio
    n_ordenes  = ('order_id', 'nunique'),       # Número de órdenes
).reset_index()

# Variables dummy (tomar la primera ocurrencia ya que son constantes dentro del grupo)
agg['Delivery_it'] = (agg['order_type'] == 'delivery').astype(int)
agg['Sucursal_2']  = (agg['branch_id'] == 2).astype(int)
agg['Sucursal_3']  = (agg['branch_id'] == 3).astype(int)

# Filtrar Q > 0 y P > 0 para logaritmos
agg = agg[(agg['Q_it'] > 0) & (agg['P_it_avg'] > 0)].copy()

# Variables logarítmicas
agg['ln_Q']  = np.log(agg['Q_it'])
agg['ln_P']  = np.log(agg['P_it_avg'])

print(f"   Observaciones del modelo: {len(agg):,}")
print(f"   Productos únicos: {agg['product_id'].nunique()}")
print(f"   Días únicos: {agg['fecha'].nunique()}")

# ─────────────────────────────────────────────────────────────────────────────
# 4. ESTIMACIÓN DEL MODELO MCO
#    ln(Q_it) = β₀ + β₁·ln(P_it) + β₂·D_it + β₃·Desc_it 
#               + δ₁·Delivery_it + γ₁·Sucursal_2 + γ₂·Sucursal_3 + u_it
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 80)
print("4. ESTIMACIÓN DEL MODELO MCO (Mínimos Cuadrados Ordinarios)")
print("=" * 80)

# Variables independientes
X_vars = ['ln_P', 'D_it_avg', 'Desc_it_avg', 'Delivery_it', 'Sucursal_2', 'Sucursal_3']
X = agg[X_vars].copy()
X = sm.add_constant(X)  # β₀ (intercepto)

y = agg['ln_Q'].copy()

# Ajuste del modelo
modelo = sm.OLS(y, X).fit()

print("\n" + str(modelo.summary()))

# ─────────────────────────────────────────────────────────────────────────────
# 5. INTERPRETACIÓN DE COEFICIENTES
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 80)
print("5. INTERPRETACIÓN ECONÓMICA DE LOS COEFICIENTES")
print("=" * 80)

coefs = modelo.params
pvals = modelo.pvalues

interpretaciones = {
    'const':       ('β₀ (Intercepto)', 
                    'Nivel base de demanda cuando todas las variables son 0'),
    'ln_P':        ('β₁ (Elasticidad precio)', 
                    'Un ↑1% en precio → cambio de {:.4f}% en cantidad demandada'),
    'D_it_avg':    ('β₂ (Efecto descuento de línea)', 
                    'Un ↑1pp en descuento de línea → cambio de {:.4f}% en cantidad'),
    'Desc_it_avg': ('β₃ (Efecto cupón de orden)',
                    'Un ↑1pp en intensidad del cupón → cambio de {:.4f}% en cantidad'),
    'Delivery_it': ('δ₁ (Efecto canal delivery)',
                    'Ser delivery vs dine_in → cambio de {:.4f}% en cantidad'),
    'Sucursal_2':  ('γ₁ (Efecto Sucursal Gulshan)',
                    'Estar en Gulshan vs Dhanmondi → cambio de {:.4f}% en cantidad'),
    'Sucursal_3':  ('γ₂ (Efecto Sucursal Banani)',
                    'Estar en Banani vs Dhanmondi → cambio de {:.4f}% en cantidad'),
}

for var, (nombre, desc) in interpretaciones.items():
    b = coefs[var]
    p = pvals[var]
    sig = "***" if p < 0.001 else "**" if p < 0.01 else "*" if p < 0.05 else "n.s."
    print(f"\n  {nombre}: {b:>10.6f}  (p={p:.4f}) {sig}")
    if var != 'const':
        pct_change = (np.exp(b) - 1) * 100  # Para variables en niveles
        if var == 'ln_P':
            print(f"    → Elasticidad: {b:.4f} (un ↑1% en precio → {b:.4f}% en demanda)")
            if abs(b) < 1:
                print(f"    → DEMANDA INELÁSTICA (|β₁| = {abs(b):.4f} < 1)")
            else:
                print(f"    → DEMANDA ELÁSTICA (|β₁| = {abs(b):.4f} > 1)")
        else:
            print(f"    → {desc.format(b * 100)}")

# ─────────────────────────────────────────────────────────────────────────────
# 6. DIAGNÓSTICO DE SUPUESTOS CLÁSICOS DEL MCO
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 80)
print("6. DIAGNÓSTICO DE SUPUESTOS CLÁSICOS")
print("=" * 80)

residuos = modelo.resid
fitted   = modelo.fittedvalues

# 6.1 Normalidad de residuos
stat_jb, p_jb = stats.jarque_bera(residuos)[:2]
stat_sw, p_sw = stats.shapiro(residuos[:5000]) if len(residuos) > 5000 else stats.shapiro(residuos)
print(f"\n  6.1 Normalidad de residuos:")
print(f"      Jarque-Bera:  stat={stat_jb:.4f}, p={p_jb:.6f}")
print(f"      Shapiro-Wilk: stat={stat_sw:.4f}, p={p_sw:.6f}")
print(f"      → {'Se rechaza' if p_jb < 0.05 else 'No se rechaza'} normalidad (α=0.05)")
print(f"      NOTA: Con muestras grandes (n>{len(residuos):,}), es común rechazar normalidad.")
print(f"            Por el TCL, los estimadores MCO son asintóticamente normales.")

# 6.2 Homocedasticidad (Breusch-Pagan)
bp_stat, bp_p, _, _ = het_breuschpagan(residuos, X)
print(f"\n  6.2 Homocedasticidad (Breusch-Pagan):")
print(f"      LM={bp_stat:.4f}, p={bp_p:.6f}")
print(f"      → {'Hay heterocedasticidad' if bp_p < 0.05 else 'No hay heterocedasticidad'} (α=0.05)")
if bp_p < 0.05:
    print(f"      → Se recomienda usar errores estándar robustos (HC1)")

# 6.3 Autocorrelación (Durbin-Watson)
dw = durbin_watson(residuos)
print(f"\n  6.3 Autocorrelación (Durbin-Watson):")
print(f"      DW={dw:.4f}")
print(f"      → {'Sin autocorrelación' if 1.5 < dw < 2.5 else 'Posible autocorrelación'}")

# 6.4 Multicolinealidad (VIF)
from statsmodels.stats.outliers_influence import variance_inflation_factor
print(f"\n  6.4 Multicolinealidad (VIF):")
for i, col in enumerate(X.columns):
    if col == 'const':
        continue
    vif = variance_inflation_factor(X.values, i)
    print(f"      {col:<15}: VIF = {vif:.4f} {'⚠️ ALTO' if vif > 10 else '✓ OK'}")

# ── Si hay heterocedasticidad, reestimar con errores robustos ──
print("\n" + "=" * 80)
print("MODELO CON ERRORES ESTÁNDAR ROBUSTOS (HC1)")
print("=" * 80)
modelo_robusto = sm.OLS(y, X).fit(cov_type='HC1')
print(modelo_robusto.summary())

# ─────────────────────────────────────────────────────────────────────────────
# 7. PRUEBA F GLOBAL Y R² AJUSTADO
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 80)
print("7. EVALUACIÓN GLOBAL DEL MODELO")
print("=" * 80)
print(f"  R²:          {modelo.rsquared:.6f}")
print(f"  R² ajustado: {modelo.rsquared_adj:.6f}")
print(f"  F-statistic: {modelo.fvalue:.4f}")
print(f"  Prob(F):     {modelo.f_pvalue:.6e}")
print(f"  AIC:         {modelo.aic:.2f}")
print(f"  BIC:         {modelo.bic:.2f}")
print(f"  Observaciones: {int(modelo.nobs):,}")

# ─────────────────────────────────────────────────────────────────────────────
# 8. CONSTRUCCIÓN DE LOS 3 ESCENARIOS
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 80)
print("8. SIMULACIÓN DE ESCENARIOS (Modelización Empresarial)")
print("=" * 80)

# Resumen por producto para escenarios
resumen = df.groupby(['product_id', 'name']).agg(
    unidades_vendidas = ('quantity', 'sum'),
    ingreso_bruto     = ('subtotal', 'sum'),
    desc_linea_total  = ('discount', 'sum'),
    precio_lista      = ('price', 'first'),
    costo_unit        = ('costo_unitario', 'first'),
    margen_unit       = ('margen_unitario', 'first'),
    margen_pct        = ('unit_price', lambda x: 0),  # Se calcula abajo
).reset_index()

# Recalcular con valores correctos
resumen['precio_efectivo'] = resumen['ingreso_bruto'] / resumen['unidades_vendidas']
resumen['costo_total']     = resumen['costo_unit'] * resumen['unidades_vendidas']
resumen['margen_total']    = resumen['ingreso_bruto'] - resumen['costo_total']
resumen['margen_pct']      = (resumen['margen_total'] / resumen['ingreso_bruto'] * 100).round(2)
resumen['participacion']   = (resumen['unidades_vendidas'] / resumen['unidades_vendidas'].sum() * 100).round(2)
resumen['desc_pct']        = (resumen['desc_linea_total'] / (resumen['precio_lista'] * resumen['unidades_vendidas']) * 100).round(2)

# Totales del cupón a nivel de orden
cupon_total = orders['coupon_discount'].fillna(0).sum()
subtotal_neto = orders['subtotal'].sum()

print("\n── ESCENARIO 1: MEZCLA ACTUAL (Línea Base S0) ──")
print(f"{'Producto':<30} {'Uds':>10} {'Part%':>6} {'Desc%':>6} {'Margen%':>8} {'Margen BDT':>12}")
print("-" * 80)
total_margen_e1 = 0
total_desc_e1 = 0
total_ingreso_e1 = 0
for _, r in resumen.sort_values('product_id').iterrows():
    print(f"{r['name']:<30} {r['unidades_vendidas']:>10,.0f} {r['participacion']:>5.1f}% "
          f"{r['desc_pct']:>5.1f}% {r['margen_pct']:>7.1f}% {r['margen_total']:>12,.0f}")
    total_margen_e1 += r['margen_total']
    total_desc_e1 += r['desc_linea_total']
    total_ingreso_e1 += r['ingreso_bruto']

desc_total_e1 = total_desc_e1 + cupon_total
margen_post_cupon_e1 = total_margen_e1 - cupon_total

print("-" * 80)
print(f"{'TOTAL':<30} {resumen['unidades_vendidas'].sum():>10,.0f} {'100.0':>6}% "
      f"{(desc_total_e1/subtotal_neto*100):>5.1f}% {(margen_post_cupon_e1/total_ingreso_e1*100):>7.1f}% "
      f"{margen_post_cupon_e1:>12,.0f}")
print(f"\n  Subtotal neto:                {subtotal_neto:>15,.0f} BDT")
print(f"  Descuentos de línea:          {total_desc_e1:>15,.0f} BDT")
print(f"  Descuentos por cupón:         {cupon_total:>15,.0f} BDT")
print(f"  TOTAL descuentos:             {desc_total_e1:>15,.0f} BDT ({desc_total_e1/subtotal_neto*100:.2f}%)")
print(f"  Margen contribución (pre):    {total_margen_e1:>15,.0f} BDT ({total_margen_e1/total_ingreso_e1*100:.2f}%)")
print(f"  Margen contribución (post):   {margen_post_cupon_e1:>15,.0f} BDT ({margen_post_cupon_e1/total_ingreso_e1*100:.2f}%)")

# ── ESCENARIO 2: REASIGNACIÓN MODERADA ──
print("\n\n── ESCENARIO 2: REASIGNACIÓN MODERADA ──")
print("  Criterio: Retirar descuentos de productos con margen < 50%")
print("            Mantener descuentos solo en productos con margen > 70%")
print("            Reducir cupones al 20% de órdenes (vs 38.65% actual)")

resumen_e2 = resumen.copy()

# Regla: si margen_pct < 50%, quitar descuento de línea
# Si margen_pct > 70%, mantener descuento pero reducido al 50% del actual
for idx, row in resumen_e2.iterrows():
    margen = (row['margen_unit'] / row['precio_lista']) * 100
    if margen < 50:
        # Quitar descuento → se recupera el ingreso
        resumen_e2.loc[idx, 'desc_linea_ajustado'] = 0
        resumen_e2.loc[idx, 'ingreso_e2'] = row['precio_lista'] * row['unidades_vendidas']
    elif margen >= 70:
        # Mantener pero moderado (50% del actual)
        resumen_e2.loc[idx, 'desc_linea_ajustado'] = row['desc_linea_total'] * 0.5
        resumen_e2.loc[idx, 'ingreso_e2'] = (row['precio_lista'] * row['unidades_vendidas']) - (row['desc_linea_total'] * 0.5)
    else:
        # Margen 50-70%: reducir al 25%
        resumen_e2.loc[idx, 'desc_linea_ajustado'] = row['desc_linea_total'] * 0.25
        resumen_e2.loc[idx, 'ingreso_e2'] = (row['precio_lista'] * row['unidades_vendidas']) - (row['desc_linea_total'] * 0.25)

resumen_e2['margen_e2'] = resumen_e2['ingreso_e2'] - resumen_e2['costo_total']

# Cupón reducido: 20% de órdenes (vs 38.65%)
cupon_e2 = cupon_total * (20 / 38.65)

total_desc_e2 = resumen_e2['desc_linea_ajustado'].sum() + cupon_e2
total_ingreso_e2 = resumen_e2['ingreso_e2'].sum()
total_margen_e2 = resumen_e2['margen_e2'].sum() - cupon_e2
subtotal_e2 = resumen_e2.apply(lambda r: r['precio_lista'] * r['unidades_vendidas'], axis=1).sum()

print(f"\n{'Producto':<30} {'Uds':>10} {'DescAnt%':>8} {'DescNew%':>8} {'Margen%':>8}")
print("-" * 80)
for _, r in resumen_e2.sort_values('product_id').iterrows():
    desc_new = (r['desc_linea_ajustado'] / (r['precio_lista'] * r['unidades_vendidas']) * 100) if r['unidades_vendidas'] > 0 else 0
    margen_new = (r['margen_e2'] / r['ingreso_e2'] * 100) if r['ingreso_e2'] > 0 else 0
    print(f"{r['name']:<30} {r['unidades_vendidas']:>10,.0f} {r['desc_pct']:>7.1f}% {desc_new:>7.1f}% {margen_new:>7.1f}%")

print("-" * 80)
print(f"\n  TOTAL descuentos E2:          {total_desc_e2:>15,.0f} BDT ({total_desc_e2/subtotal_e2*100:.2f}%)")
print(f"  Margen contribución E2:       {total_margen_e2:>15,.0f} BDT ({total_margen_e2/total_ingreso_e2*100:.2f}%)")
print(f"  Ahorro vs E1:                 {(desc_total_e1 - total_desc_e2):>15,.0f} BDT")

# ── ESCENARIO 3: MEZCLA OPTIMIZADA (Preparación para LP) ──
print("\n\n── ESCENARIO 3: MEZCLA OPTIMIZADA (Base para Programación Lineal) ──")
print("  Objetivo: Maximizar margen global")
print("  Restricciones:")
print("    - Volumen total constante (4,995,377 unidades)")
print("    - Demanda mínima por producto: 80% del volumen actual")
print("    - Demanda máxima por producto: 120% del volumen actual")
print("    - Costo total de descuentos ≤ 5.00% del subtotal")
print("    - Precios de lista constantes")
print("  → Este escenario se formaliza y resuelve con LP en Optimización Empresarial I")

# Preparar datos para LP
print(f"\n  Parámetros para el modelo de Programación Lineal:")
print(f"  {'Producto':<30} {'Precio':>8} {'Costo':>8} {'Margen':>8} {'Q_min':>8} {'Q_max':>8}")
print(f"  {'-'*78}")
vol_total = resumen['unidades_vendidas'].sum()
for _, r in resumen.sort_values('product_id').iterrows():
    q_min = int(r['unidades_vendidas'] * 0.80)
    q_max = int(r['unidades_vendidas'] * 1.20)
    print(f"  {r['name']:<30} {r['precio_lista']:>8.0f} {r['costo_unit']:>8.2f} "
          f"{r['margen_unit']:>8.2f} {q_min:>8,} {q_max:>8,}")
print(f"\n  Volumen total constante: {vol_total:,.0f} unidades")

# ─────────────────────────────────────────────────────────────────────────────
# 9. MATRIZ COMPARATIVA DE ESCENARIOS
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 80)
print("9. MATRIZ COMPARATIVA DE DESEMPEÑO POR ESCENARIO")
print("=" * 80)

print(f"\n  {'Indicador':<45} {'E1 (Actual)':>15} {'E2 (Moderado)':>15} {'E3 (Óptimo)':>15}")
print(f"  {'-'*90}")
print(f"  {'Volumen total (unidades)':<45} {vol_total:>15,.0f} {vol_total:>15,.0f} {vol_total:>15,.0f}")
print(f"  {'Costo de descuentos (BDT)':<45} {desc_total_e1:>15,.0f} {total_desc_e2:>15,.0f} {'(por resolver)':>15}")
print(f"  {'% Descuento s/ subtotal':<45} {desc_total_e1/subtotal_neto*100:>14.2f}% {total_desc_e2/subtotal_e2*100:>14.2f}% {'≤ 5.00%':>15}")
print(f"  {'Margen contribución (BDT)':<45} {margen_post_cupon_e1:>15,.0f} {total_margen_e2:>15,.0f} {'(por resolver)':>15}")
print(f"  {'% Margen global':<45} {margen_post_cupon_e1/total_ingreso_e1*100:>14.2f}% {total_margen_e2/total_ingreso_e2*100:>14.2f}% {'≥ 62.00%':>15}")
print(f"  {'Ahorro vs E1 (BDT)':<45} {'—':>15} {(desc_total_e1 - total_desc_e2):>15,.0f} {'(por resolver)':>15}")

# ─────────────────────────────────────────────────────────────────────────────
# 10. ANÁLISIS DE SENSIBILIDAD
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 80)
print("10. ANÁLISIS DE SENSIBILIDAD — Umbral de Caída de Volumen")
print("=" * 80)
print("  ¿Cuánto puede caer el volumen antes de que E2 deje de ser mejor que E1?")

margen_e1_ref = margen_post_cupon_e1
for caida in [0, 1, 2, 3, 5, 7, 10]:
    vol_ajustado = vol_total * (1 - caida/100)
    # Proporcionalmente el margen cae
    margen_e2_ajustado = total_margen_e2 * (1 - caida/100)
    diferencia = margen_e2_ajustado - margen_e1_ref
    mejor = "E2 >" if diferencia > 0 else "E1 >"
    print(f"  Caída {caida:>2}%: Vol={vol_ajustado:>12,.0f} | Margen E2={margen_e2_ajustado:>15,.0f} | "
          f"vs E1={margen_e1_ref:>15,.0f} | {mejor} ({diferencia:>+15,.0f} BDT)")

# Umbral exacto de equilibrio
if total_margen_e2 > 0:
    umbral = (1 - margen_e1_ref / total_margen_e2) * 100
    print(f"\n  → UMBRAL DE EQUILIBRIO: Caída de {umbral:.2f}% en volumen")
    print(f"    Si la demanda cae menos de {umbral:.2f}%, E2 sigue siendo superior a E1.")

# ─────────────────────────────────────────────────────────────────────────────
# 11. EXPORTAR RESULTADOS
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "=" * 80)
print("11. EXPORTANDO RESULTADOS")
print("=" * 80)

# Guardar dataset de regresión
agg.to_csv(f'{OUT}/dataset_regresion_mco.csv', index=False)
print(f"  ✓ Dataset regresión: {OUT}/dataset_regresion_mco.csv")

# Guardar resumen de productos
resumen.to_csv(f'{OUT}/resumen_productos_e1.csv', index=False)
print(f"  ✓ Resumen productos E1: {OUT}/resumen_productos_e1.csv")

resumen_e2.to_csv(f'{OUT}/resumen_productos_e2.csv', index=False)
print(f"  ✓ Resumen productos E2: {OUT}/resumen_productos_e2.csv")

# Guardar coeficientes del modelo
coef_df = pd.DataFrame({
    'Variable': modelo.params.index,
    'Coeficiente': modelo.params.values,
    'Std_Error': modelo.bse.values,
    't_value': modelo.tvalues.values,
    'p_value': modelo.pvalues.values,
    'IC_2.5%': modelo.conf_int()[0].values,
    'IC_97.5%': modelo.conf_int()[1].values,
})
coef_df.to_csv(f'{OUT}/coeficientes_mco.csv', index=False)
print(f"  ✓ Coeficientes MCO: {OUT}/coeficientes_mco.csv")

# Guardar summary como texto
with open(f'{OUT}/modelo_mco_summary.txt', 'w', encoding='utf-8') as f:
    f.write(str(modelo.summary()))
    f.write('\n\n--- MODELO ROBUSTO (HC1) ---\n\n')
    f.write(str(modelo_robusto.summary()))
print(f"  ✓ Summary completo: {OUT}/modelo_mco_summary.txt")

print("\n" + "=" * 80)
print("✅ MODELIZACIÓN COMPLETADA EXITOSAMENTE")
print("=" * 80)
print(f"\nResumen para el avance de Modelización Empresarial I:")
print(f"  • Modelo log-lineal de demanda estimado por MCO")
print(f"  • β₁ (elasticidad precio): {coefs['ln_P']:.6f}")
print(f"  • R² ajustado: {modelo.rsquared_adj:.6f}")
print(f"  • 3 escenarios construidos y comparados")
print(f"  • Análisis de sensibilidad con umbral de equilibrio")
print(f"  • Escenario 3 listo para formalizarse con LP (Optimización)")
