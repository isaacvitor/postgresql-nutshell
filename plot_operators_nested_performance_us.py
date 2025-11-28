import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import matplotlib.ticker as ticker

# ===========================
# LOAD DATA
# ===========================
df = pd.read_csv("jsonb_performance_results.csv")

# Convert execution time from ms → µs (like PGConf plots)
df["execution_us"] = df["execution_time"] * 1000

# ===========================
# MAP size → BYTES APPROX (log domain)
# ===========================
bytes_min = 100
bytes_max = 1_000_000

df["bytes"] = np.exp(
    np.interp(
        df["size"],
        (df["size"].min(), df["size"].max()),
        (np.log(bytes_min), np.log(bytes_max))
    )
)

operators = ["arrow", "path", "jsonpath", "subscript"]
titles = {
    "arrow": "->",
    "path": "#>",
    "jsonpath": "jsonpath",
    "subscript": "subscripting"
}

# ===========================
# Style — Dark Background 
# ===========================
plt.style.use("dark_background")

fig, axes = plt.subplots(1, 4, figsize=(22, 5), sharey=True)
axes = axes.flatten()

cmap = plt.cm.get_cmap("rainbow")

# ===========================
# Ploting loops
# ===========================
last_scatter = None

for i, op in enumerate(operators):
    sub = df[df["operator"] == op]

    sc = axes[i].scatter(
        sub["bytes"],
        sub["execution_us"],
        c=sub["level"],
        cmap=cmap,
        s=15,
        alpha=0.9
    )
    last_scatter = sc

    # Log scales
    axes[i].set_xscale("log")
    axes[i].set_yscale("log")

    # --- Fix ticks ---
    axes[i].yaxis.set_major_locator(ticker.LogLocator(base=10, numticks=10))
    axes[i].yaxis.set_major_formatter(ticker.ScalarFormatter())
    axes[i].yaxis.get_major_formatter().set_scientific(False)
    axes[i].tick_params(axis='y', labelsize=8)

    # X ticks
    xticks = [100, 1_000, 10_000, 100_000, 1_000_000]
    xtick_labels = ["100", "1K", "10K", "100K", "1M"]
    axes[i].set_xticks(xticks)
    axes[i].set_xticklabels(xtick_labels)

    # Grid
    axes[i].grid(color="#666", alpha=0.4)

    # Titles
    axes[i].set_title(
        titles[op],
        fontsize=12,
        fontweight="bold",
        backgroundcolor="#555",
        pad=6
    )

    # Labels
    axes[i].set_xlabel("raw jsonb size, bytes")

axes[0].set_ylabel("execution time, µs")

# ===========================
# Colorbar to the right of the plots
# ===========================
cbar = fig.colorbar(
    last_scatter,
    ax=axes,
    location="right",
    pad=0.05,
    fraction=0.03
)
cbar.set_label("nesting level")

# ===========================
# Layout Configuration
# ===========================
plt.subplots_adjust(
    left=0.04,
    right=0.85,
    top=0.92,
    bottom=0.112,
    wspace=0.15
)

plt.savefig("operators_nested_performance_bench_dark.png", dpi=200)
plt.show()
