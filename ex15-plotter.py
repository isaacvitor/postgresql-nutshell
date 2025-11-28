#!/usr/bin/env python3
# plot_pgconf_style.py
# Requires: pip install pandas matplotlib numpy

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import math
import os

CANDIDATES = [
    "ex15-bench_results.csv"
]

csv_path = None
for c in CANDIDATES:
    if os.path.exists(c):
        csv_path = c
        break

if csv_path is None:
    raise FileNotFoundError("Nenhum CSV encontrado. Rode o benchmark primeiro.")

df = pd.read_csv(csv_path)
print(f"Loaded {csv_path} with {len(df)} rows")

# Prefer 'bytes_raw'. If not present, fallback to log mapping (less ideal).
if 'bytes_raw' in df.columns and not df['bytes_raw'].isnull().all():
    df['bytes'] = df['bytes_raw'].astype(float)
else:
    # fallback: map size_index to [100..1_000_000]
    if 'size' in df.columns:
        size_col = 'size'
    elif 'size_index' in df.columns:
        size_col = 'size_index'
    else:
        raise RuntimeError("Nenhuma coluna bytes_raw nem size/szie_index disponível no CSV.")
    bytes_min = 100.0
    bytes_max = 1_000_000.0
    df['bytes'] = np.exp(
        np.interp(
            df[size_col].astype(float),
            (df[size_col].min(), df[size_col].max()),
            (np.log(bytes_min), np.log(bytes_max))
        )
    )

# time: get correct column and convert ms -> µs
if 'execution_time_ms_median' in df.columns:
    df['time_ms'] = df['execution_time_ms_median'].astype(float)
elif 'execution_time' in df.columns:
    df['time_ms'] = df['execution_time'].astype(float)
else:
    raise RuntimeError("Nenhuma coluna de tempo ('execution_time_ms_median' ou 'execution_time') encontrada.")

df['time_us'] = df['time_ms'] * 1000.0

# plot parameters
operators = ['arrow', 'path', 'subscript', 'jsonpath']
titles = {
    'arrow': '-> operator',
    'path': '#> operator',
    'subscript': '[] subscript',
    'jsonpath': 'jsonpath'
}

fig, axes = plt.subplots(2, 2, figsize=(16, 10), sharey=True)
axes = axes.flatten()

if 'level' not in df.columns:
    raise RuntimeError("Coluna 'level' não encontrada no CSV (necessária para color mapping).")
vmin = int(df['level'].min())
vmax = int(df['level'].max())
norm = mpl.colors.Normalize(vmin=vmin, vmax=vmax)
cmap = plt.get_cmap("viridis")
mappable = mpl.cm.ScalarMappable(norm=norm, cmap=cmap)
mappable.set_array([])

# Y ticks: include 0.1 -> 10^(-1)..10^max
max_time = df['time_us'].replace([np.inf, -np.inf], np.nan).dropna().max()
if np.isnan(max_time) or max_time <= 0:
    max_power = 3
else:
    max_power = math.ceil(math.log10(max_time))
yticks = [10 ** p for p in range(-1, max_power + 1)]
xticks = [100, 1_000, 10_000, 100_000, 1_000_000]

def x_formatter(val, pos):
    if val >= 1_000_000:
        return f"{int(val/1_000_000)}M"
    if val >= 1000:
        return f"{int(val/1000)}K"
    return str(int(val))

def y_formatter(val, pos):
    if val >= 1:
        return f"{int(val)}"
    else:
        return f"{val:.1g}"

minor_locator = mpl.ticker.LogLocator(base=10.0, subs=np.arange(2, 10) * 0.1)

for i, op in enumerate(operators):
    ax = axes[i]
    sub = df[df["operator"] == op]
    if sub.empty:
        ax.text(0.5, 0.5, f"No data for {op}", ha='center', va='center')
        continue

    sc = ax.scatter(
        sub["bytes"],
        sub["time_us"],
        c=sub["level"],
        cmap=cmap,
        norm=norm,
        s=30,
        alpha=0.85,
        edgecolors='none'
    )

    ax.set_title(titles.get(op, op), fontsize=12, pad=8)
    ax.set_xlabel("raw jsonb size, bytes", fontsize=10)
    if i % 2 == 0:
        ax.set_ylabel("execution time, µs", fontsize=10)

    ax.set_xscale("log")
    ax.set_yscale("log")

    ax.set_xticks(xticks)
    ax.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(x_formatter))

    ax.set_yticks(yticks)
    ax.yaxis.set_major_formatter(mpl.ticker.FuncFormatter(y_formatter))
    ax.yaxis.set_minor_locator(minor_locator)

    ax.grid(which='major', linestyle='--', alpha=0.25)
    ax.grid(which='minor', linestyle=':', alpha=0.12)
    ax.margins(x=0.02, y=0.05)

cax = fig.add_axes([0.92, 0.15, 0.02, 0.7])
cb = fig.colorbar(mappable, cax=cax)
cb.set_label("nesting level", fontsize=10)
cb.set_ticks(np.arange(vmin, vmax + 1, 1))

plt.subplots_adjust(left=0.06, bottom=0.06, right=0.9, top=0.96, wspace=0.12, hspace=0.18)

outname = "ex15-bench_results.png"
plt.savefig(outname, dpi=200, bbox_inches='tight')
print("Saved", outname)
plt.show()
