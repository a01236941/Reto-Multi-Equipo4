"""Imputación de la base SIMA con SAITS (parte Transformer del método
Transformer-Diffusion de Gómez Santos et al., 2027).

Entrada:  data/processed/sima_horario_AAAA.csv.gz  (base limpia del pipeline en R)
Salida:   data/imputada/sima_imputada_AAAA_sN.csv.gz
          reports/imputacion_saits/*.csv y resumen.json

Ejecutar desde la raíz del proyecto:  python python/imputar_saits.py
"""
import glob, json, os, sys, time
import numpy as np
import pandas as pd
import torch
from pypots.imputation import SAITS

SEMILLA = 20260930
L = 48            # horas por ventana
HUECO_MAX = 24    # sólo se imputan huecos de hasta 24 horas seguidas
EPOCAS = int(os.environ.get("EPOCAS", 15))
np.random.seed(SEMILLA); torch.manual_seed(SEMILLA)

VARS = ["CO", "NO", "NO2", "NOX", "O3", "PM10", "PM2.5", "PRS", "RAINF",
        "RH", "SO2", "SR", "TOUT", "WSR"]
NO_NEG = ["CO", "NO", "NO2", "NOX", "O3", "PM10", "PM2.5", "RAINF", "SO2", "SR", "WSR"]
MEDIDAS = VARS + ["WDR_sin", "WDR_cos"]
CALENDARIO = ["hora_sin", "hora_cos", "mes_sin", "mes_cos"]
RASGOS = MEDIDAS + CALENDARIO
NM = len(MEDIDAS)
SAL_R = "reports/imputacion_saits"
os.makedirs(SAL_R, exist_ok=True); os.makedirs("data/imputada", exist_ok=True)

# 1. Leer la base limpia -------------------------------------------------------
archivos = sorted(glob.glob("data/processed/sima_horario_*.csv.gz"))
if len(archivos) != 7:
    sys.exit("No encuentro los 7 archivos de data/processed. Ejecuta desde la raíz del proyecto.")
df = pd.concat([pd.read_csv(a, usecols=["fecha_hora", "estacion"] + VARS + ["WDR"]) for a in archivos])
df["fecha_hora"] = pd.to_datetime(df["fecha_hora"])
print("Filas leídas:", len(df))

# 1b. Reglas físicas adicionales (lecturas imposibles que quedaron tras la limpieza en R)
reglas = [("TOUT", lambda x: (x < -15) | (x > 50), "temperatura fuera de -15 a 50 °C"),
          ("SR", lambda x: x > 2, "radiación solar mayor de 2 kW/m2"),
          ("WSR", lambda x: x > 150, "viento mayor de 150 km/h"),
          ("RAINF", lambda x: x > 100, "lluvia mayor de 100 mm en una hora"),
          ("PRS", lambda x: x < 650, "presión menor de 650 mmHg"),
          ("PM10", lambda x: x >= 999, "valor de saturación 999 o más"),
          ("PM2.5", lambda x: x >= 999, "valor de saturación 999 o más")]
corr = []
for v, regla, motivo in reglas:
    malo = regla(df[v]).fillna(False).values
    if malo.any():
        z = df.loc[malo, ["estacion", "fecha_hora", v]].rename(columns={v: "valor_original"})
        z["variable"] = v; z["motivo"] = motivo; corr.append(z)
        df.loc[malo, v] = np.nan
corr = pd.concat(corr); corr.to_csv(f"{SAL_R}/correcciones_adicionales.csv", index=False)
print("Lecturas imposibles pasadas a NA:", len(corr))
print(corr.groupby(["variable", "motivo"]).size())

# 2. Rejilla horaria completa por estación -------------------------------------
partes = []
for est, g in df.groupby("estacion"):
    g = g.set_index("fecha_hora").sort_index()
    rejilla = pd.date_range(g.index.min(), g.index.max(), freq="h")
    g = g.reindex(rejilla)
    g["fila_original"] = g["estacion"].notna()
    g["estacion"] = est
    partes.append(g.rename_axis("fecha_hora").reset_index())
base = pd.concat(partes, ignore_index=True)

calma = base["WSR"] == 0
base["WDR_sin"] = np.where(calma, 0.0, np.sin(np.deg2rad(base["WDR"])))
base["WDR_cos"] = np.where(calma, 0.0, np.cos(np.deg2rad(base["WDR"])))
base.loc[base["WDR"].isna() & ~calma, ["WDR_sin", "WDR_cos"]] = np.nan
h = base["fecha_hora"].dt.hour; m = base["fecha_hora"].dt.month - 1
base["hora_sin"], base["hora_cos"] = np.sin(2*np.pi*h/24), np.cos(2*np.pi*h/24)
base["mes_sin"], base["mes_cos"] = np.sin(2*np.pi*m/12), np.cos(2*np.pi*m/12)
base["anio"] = base["fecha_hora"].dt.year

# 3. Escalado por estación con estadísticos de 2020-2024 ------------------------
Z = base[RASGOS].astype("float64").copy()
for v in NO_NEG:
    Z[v] = np.log1p(Z[v].clip(lower=0))
entren = base["anio"] <= 2024
sd_global = Z.loc[entren, MEDIDAS].std()
estad = {}
for est in base["estacion"].unique():
    sel = (base["estacion"] == est).values
    ref = sel & entren.values
    if ref.sum() < 1000:
        ref = sel
    mu = Z.loc[ref, MEDIDAS].mean()
    # Piso de la desviación para estaciones casi constantes (p. ej. lluvia).
    sd = np.maximum(Z.loc[ref, MEDIDAS].std().fillna(1), 0.25 * sd_global)
    mu = mu.fillna(0)
    Z.loc[sel, MEDIDAS] = (Z.loc[sel, MEDIDAS] - mu) / sd
    estad[est] = (mu, sd)
# Sólo para la entrada del modelo: se recortan valores extremos a ±8 desviaciones.
Z[MEDIDAS] = Z[MEDIDAS].clip(-8, 8)

def deshacer(zvals, est):
    mu, sd = estad[est]
    x = zvals * sd.values + mu.values
    out = pd.DataFrame(x, columns=MEDIDAS)
    for v in NO_NEG:
        out[v] = np.expm1(out[v]).clip(lower=0)
    out["RH"] = out["RH"].clip(0, 100)
    return out

# 4. Ventanas --------------------------------------------------------------------
def ventanas(mascara, paso):
    X = []
    for est in base["estacion"].unique():
        sel = np.where((base["estacion"] == est).values & mascara)[0]
        if len(sel) < L:
            continue
        arr = Z.values[sel].astype("float32")
        for i in range(0, len(arr) - L + 1, paso):
            w = arr[i:i+L]
            if np.isfinite(w[:, :NM]).mean() >= 0.3:
                X.append(w)
    return np.stack(X)

anio = base["anio"].values
X_tr = ventanas(anio <= 2024, 24)
X_va = ventanas(anio == 2025, L)
X_te = ventanas(anio == 2026, L)
print("Ventanas entrenamiento/validación/prueba:", len(X_tr), len(X_va), len(X_te))

def ocultar(X, prob=0.25, largos=(1, 3, 6, 12, 24), semilla=1):
    """Oculta bloques de horas observadas. Devuelve X con huecos, máscara y largo del bloque."""
    rng = np.random.default_rng(semilla)
    Xh = X.copy(); mask = np.zeros(X.shape, bool); largo = np.zeros(X.shape, np.int16)
    for n in range(X.shape[0]):
        for f in range(NM):
            if rng.random() < prob:
                lb = int(rng.choice(largos)); ini = int(rng.integers(0, L - lb + 1))
                obs = np.isfinite(X[n, ini:ini+lb, f])
                idx = np.arange(ini, ini+lb)[obs]
                Xh[n, idx, f] = np.nan; mask[n, idx, f] = True; largo[n, idx, f] = lb
    return Xh, mask, largo

X_va_h, _, _ = ocultar(X_va, semilla=2)

# 5. Entrenamiento de SAITS ------------------------------------------------------
modelo = SAITS(n_steps=L, n_features=len(RASGOS), n_layers=2, d_model=64, n_heads=4,
               d_k=16, d_v=16, d_ffn=128, dropout=0.1, batch_size=64, epochs=EPOCAS,
               patience=min(3, EPOCAS - 1) if EPOCAS > 1 else None, saving_path=None, verbose=True)
t0 = time.time()
modelo.fit({"X": X_tr}, {"X": X_va_h, "X_ori": X_va})
print("Entrenamiento: %.1f min" % ((time.time() - t0) / 60))

def imputar(X):
    salida = []
    for i in range(0, len(X), 2000):
        salida.append(modelo.predict({"X": X[i:i+2000]})["imputation"])
    return np.concatenate(salida)

# 6. Prueba con 2026: SAITS contra media, mediana, interpolación y último valor ----
X_te_h, mask_te, largo_te = ocultar(X_te, semilla=3)
P_saits = imputar(X_te_h)

def interp(X, metodo):
    out = X.copy()
    for n in range(X.shape[0]):
        d = pd.DataFrame(X[n, :, :NM])
        d = d.interpolate(limit_direction="both") if metodo == "lineal" else d.ffill().bfill()
        out[n, :, :NM] = d.values
    return out

P_lin = interp(X_te_h, "lineal"); P_locf = interp(X_te_h, "locf")
med_tr = np.nanmedian(X_tr[:, :, :NM].reshape(-1, NM), axis=0)
P_media = np.where(np.isnan(X_te_h), 0.0, X_te_h)   # 0 = media de entrenamiento en escala z
P_mediana = X_te_h.copy()
for f in range(NM):
    P_mediana[:, :, f] = np.where(np.isnan(X_te_h[:, :, f]), med_tr[f], X_te_h[:, :, f])

# Métricas en escala estandarizada para poder comparar variables con unidades distintas.
filas = []; filas_b = []
for nombre, P in [("SAITS", P_saits), ("Interpolación lineal", P_lin),
                  ("Último valor observado", P_locf), ("Media", P_media), ("Mediana", P_mediana)]:
    for f, v in enumerate(MEDIDAS):
        mk = mask_te[:, :, f]
        if mk.sum() == 0:
            continue
        real = X_te[:, :, f][mk]; est = P[:, :, f][mk]
        ok = np.isfinite(est)
        mae = np.mean(np.abs(real[ok] - est[ok]))
        r = np.corrcoef(real[ok], est[ok])[0, 1] if np.std(est[ok]) > 0 else 0.0
        filas.append({"metodo": nombre, "variable": v, "celdas": int(mk.sum()),
                      "MAE_z": mae, "correlacion": r})
    for lb in (1, 3, 6, 12, 24):
        mk = mask_te[:, :, :NM] & (largo_te[:, :, :NM] == lb)
        real = X_te[:, :, :NM][mk]; est = P[:, :, :NM][mk]; ok = np.isfinite(est)
        filas_b.append({"metodo": nombre, "horas_bloque": lb,
                        "MAE_z": np.mean(np.abs(real[ok] - est[ok]))})
met = pd.DataFrame(filas); met_b = pd.DataFrame(filas_b)
met.to_csv(f"{SAL_R}/metricas_prueba_2026_por_variable.csv", index=False)
met_b.to_csv(f"{SAL_R}/metricas_prueba_2026_por_bloque.csv", index=False)
resumen_met = met.groupby("metodo")[["MAE_z", "correlacion"]].mean().sort_values("MAE_z")
resumen_met.to_csv(f"{SAL_R}/metricas_prueba_2026_resumen.csv")
print(resumen_met)
print(met_b.pivot(index="horas_bloque", columns="metodo", values="MAE_z"))

# 7. Imputación de toda la base ----------------------------------------------------
imp_z = np.full((len(base), NM), np.nan)
for est in base["estacion"].unique():
    sel = np.where((base["estacion"] == est).values)[0]
    arr = Z.values[sel].astype("float32")
    n = len(arr); pad = (-n) % L
    arr_p = np.vstack([arr, np.full((pad, arr.shape[1]), np.nan, "float32")])
    # Dos pasadas desfasadas 24 h y promedio para suavizar los bordes de ventana.
    acum = np.zeros((len(arr_p), NM)); cuenta = np.zeros((len(arr_p), NM))
    for desf in (0, L // 2):
        a = arr_p[desf:]; k = len(a) // L
        if k == 0:
            continue
        W = a[:k*L].reshape(k, L, -1).copy()
        W[:, :, NM:] = np.nan_to_num(W[:, :, NM:])
        P = imputar(W)[:, :, :NM].reshape(-1, NM)
        acum[desf:desf+k*L] += P; cuenta[desf:desf+k*L] += 1
    imp_z[sel] = (acum / np.maximum(cuenta, 1))[:n]

final = base[["fecha_hora", "estacion", "fila_original"] + VARS + ["WDR"]].copy()
resumen = []
for est in base["estacion"].unique():
    sel = (base["estacion"] == est).values
    val = deshacer(imp_z[sel], est)
    for v in VARS + ["WDR"]:
        col = "WDR_sin" if v == "WDR" else v
        falt = base.loc[sel, col].isna().values
        # Largo de cada racha de faltantes.
        grupo = np.cumsum(~falt); racha = pd.Series(falt).groupby(grupo).transform("sum").values
        usar = falt & (racha <= HUECO_MAX)
        if v == "WDR":
            nuevo = (np.rad2deg(np.arctan2(val["WDR_sin"].values, val["WDR_cos"].values)) % 360)
        else:
            nuevo = val[v].values
        idx = np.where(sel)[0][usar]
        final.loc[idx, v] = nuevo[usar]
        final.loc[np.where(sel)[0], v + "_imp"] = usar.astype(int)
for v in VARS + ["WDR"]:
    final[v + "_imp"] = final[v + "_imp"].astype(int)

# Filas que no existían en el Excel: sólo se guardan si se imputó algo en ellas.
imp_cols = [v + "_imp" for v in VARS + ["WDR"]]
final = final[final["fila_original"] | (final[imp_cols].sum(axis=1) > 0)].copy()
final["fila_agregada"] = (~final["fila_original"]).astype(int)
final = final.drop(columns="fila_original")

orig = final[final["fila_agregada"] == 0]
for v in VARS + ["WDR"]:
    faltaban = int(df[v].isna().sum())
    imputados = int(orig[v + "_imp"].sum())
    resumen.append({"variable": v, "registros": len(df), "faltantes": faltaban,
                    "pct_faltantes": round(100*faltaban/len(df), 2),
                    "imputados_SAITS": imputados,
                    "pct_imputado_de_faltantes": round(100*imputados/max(faltaban, 1), 2),
                    "siguen_faltando": faltaban - imputados,
                    "pct_siguen_faltando": round(100*(faltaban-imputados)/len(df), 2)})
res = pd.DataFrame(resumen); res.to_csv(f"{SAL_R}/resumen_imputacion.csv", index=False)
print(res)

for v in VARS + ["WDR"]:
    final[v] = final[v].round(4)
final["fecha_hora"] = final["fecha_hora"].dt.strftime("%Y-%m-%d %H:%M:%S")
final = final.sort_values(["estacion", "fecha_hora"])
# Un archivo por semestre.
sem = final["fecha_hora"].str[:4] + "_s" + np.where(final["fecha_hora"].str[5:7].astype(int) <= 6, "1", "2")
for a, g in final.groupby(sem):
    ruta = f"data/imputada/sima_imputada_{a}.csv.gz"
    g.to_csv(ruta, index=False)
    print(ruta, len(g), "filas", round(os.path.getsize(ruta)/2**20, 1), "MB")

json.dump({"semilla": SEMILLA, "horas_ventana": L, "hueco_maximo_imputado_h": HUECO_MAX,
           "epocas_max": EPOCAS, "ventanas": [len(X_tr), len(X_va), len(X_te)],
           "rasgos": RASGOS, "filas_salida": int(len(final)),
           "filas_agregadas": int(final["fila_agregada"].sum()),
           "celdas_imputadas": int(res["imputados_SAITS"].sum()),
           "faltantes_totales": int(res["faltantes"].sum())},
          open(f"{SAL_R}/resumen.json", "w"), indent=2, ensure_ascii=False)
print("Listo.")
