"""Base final para modelar O3.
Entrada: data/imputada/sima_imputada_AAAA.csv (salida de imputar_saits.py)
Salida:  data/final/sima_modelo_o3_AAAA.csv y reports/imputacion_saits/base_final_resumen.csv
Ejecutar desde la raíz del proyecto:  python python/base_final.py
"""
import glob, os
import numpy as np
import pandas as pd

d = pd.concat([pd.read_csv(a) for a in sorted(glob.glob("data/imputada/sima_imputada_*.csv"))])
d["fecha_hora"] = pd.to_datetime(d["fecha_hora"])
n_total = len(d)

# Atributos derivados
d["anio"] = d.fecha_hora.dt.year; d["mes"] = d.fecha_hora.dt.month; d["hora"] = d.fecha_hora.dt.hour
d["temporada"] = np.select([d.mes.isin([12, 1, 2]), d.mes.isin([3, 4, 5]), d.mes.isin([6, 7, 8])],
                           ["invierno", "primavera", "verano"], "otono")
d["hora_sin"] = np.sin(2*np.pi*d.hora/24); d["hora_cos"] = np.cos(2*np.pi*d.hora/24)
d["mes_sin"] = np.sin(2*np.pi*(d.mes-1)/12); d["mes_cos"] = np.cos(2*np.pi*(d.mes-1)/12)
calma = d.WSR == 0
d["WDR_sin"] = np.where(calma, 0.0, np.sin(np.deg2rad(d.WDR)))
d["WDR_cos"] = np.where(calma, 0.0, np.cos(np.deg2rad(d.WDR)))

predictoras = ["TOUT", "RH", "SR", "RAINF", "PRS", "WSR", "NO", "NO2", "NOX", "CO",
               "WDR_sin", "WDR_cos", "hora_sin", "hora_cos", "mes_sin", "mes_cos"]

# La respuesta debe ser O3 medido, nunca imputado
sin_o3 = d.O3.isna() | (d.O3_imp == 1)
n_sin_o3 = int(sin_o3.sum()); d = d[~sin_o3]
incompleta = d[predictoras].isna().any(axis=1)
n_incompleta = int(incompleta.sum()); d = d[~incompleta].copy()

# Dummies k-1 (referencias: estación CE e invierno)
dum = pd.get_dummies(d[["estacion", "temporada"]].astype(
    {"temporada": pd.CategoricalDtype(["invierno", "primavera", "verano", "otono"])}),
    drop_first=True, dtype=int)
d["filas_con_imputacion"] = d[[c for c in d.columns if c.endswith("_imp")]].sum(axis=1).gt(0).astype(int)
cols = ["fecha_hora", "estacion", "anio", "mes", "hora", "temporada", "O3"] + predictoras + ["filas_con_imputacion"]
final = pd.concat([d[cols], dum], axis=1)
for c in predictoras:
    final[c] = final[c].round(4)

res = pd.DataFrame({"concepto": ["filas_base_imputada", "eliminadas_sin_O3_medido",
                                 "eliminadas_falta_predictora", "filas_base_final"],
                    "filas": [n_total, n_sin_o3, n_incompleta, len(final)]})
res["porcentaje"] = (100 * res.filas / n_total).round(2)
os.makedirs("reports/imputacion_saits", exist_ok=True)
res.to_csv("reports/imputacion_saits/base_final_resumen.csv", index=False)
print(res)

os.makedirs("data/final", exist_ok=True)
final["fecha_hora"] = final.fecha_hora.dt.strftime("%Y-%m-%d %H:%M:%S")
# un archivo por semestre para quedar muy por debajo del límite de subida de GitHub
sem = final["anio"].astype(str) + "_s" + np.where(final["mes"] <= 6, "1", "2")
for a, g in final.groupby(sem):
    ruta = f"data/final/sima_modelo_o3_{a}.csv"
    g.to_csv(ruta, index=False)
    print(ruta, len(g), "filas", round(os.path.getsize(ruta)/2**20, 1), "MB")
print("Columnas:", final.shape[1])
