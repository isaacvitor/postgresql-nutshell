import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

df = pd.read_csv("jsonb_performance_results.csv")

operators = ['arrow', 'path', 'subscript', 'jsonpath']
titles = {
    'arrow': '-> operator',
    'path': '#> operator',
    'subscript': '[] subscript',
    'jsonpath': 'jsonpath'
}

# -----------------------------------------
# MAPEAR size (0–119) → bytes (~100 to 1M)
# -----------------------------------------
bytes_min = 100         # ~100 bytes
bytes_max = 1_000_000   # 1 MB

# Logarithmic mapping
df["bytes"] = np.exp(
    np.interp(
        df["size"],
        (df["size"].min(), df["size"].max()),
        (np.log(bytes_min), np.log(bytes_max))
    )
)

# -----------------------------------------
# Generate plots
# -----------------------------------------
fig, axes = plt.subplots(2, 2, figsize=(16, 10), sharey=True)
axes = axes.flatten()

last_scatter = None

for i, op in enumerate(operators):
    sub = df[df["operator"] == op]

    sc = axes[i].scatter(
        sub["bytes"],                # X axis in approximate real bytes
        sub["execution_time"],       # Y axis in ms
        c=sub["level"],
        cmap="viridis",
        s=30,
        alpha=0.7
    )
    last_scatter = sc

    axes[i].set_title(titles[op])
    axes[i].set_xlabel("raw jsonb size, bytes")
    axes[i].set_ylabel("execution time, ms")

    # X axis in logarithmic scale
    axes[i].set_xscale("log")

    axes[i].grid(True, alpha=0.3)

# -----------------------------------------
# Custom ticks on X axis
# -----------------------------------------
ticks = [100, 1_000, 10_000, 100_000, 1_000_000]
tick_labels = ["100", "1K", "10K", "100K", "1M"]

for ax in axes:
    ax.set_xticks(ticks)
    ax.set_xticklabels(tick_labels)

# -----------------------------------------
# Colorbar to the right of the plots
# -----------------------------------------
cax = fig.add_axes([0.92, 0.15, 0.02, 0.7])
cbar = fig.colorbar(last_scatter, cax=cax)
cbar.set_label("nesting level")

# -----------------------------------------
# Layout Configuration
# -----------------------------------------
plt.subplots_adjust(
    left=0.043,
    bottom=0.058,
    right=0.91,
    top=0.964,
    wspace=0.053,
    hspace=0.193
)

plt.savefig("operators_nested_performance_bench_light.png", dpi=200)
plt.show()
