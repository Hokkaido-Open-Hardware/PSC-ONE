import re
import pandas as pd
import matplotlib.pyplot as plt

#LOG_FILE = "./log_yosys/yosys_PSC_RV32ISP_core.log"
LOG_FILE = "./log_yosys/yosys_SystolicArray2x2_Ctrl.log"

# ============================================================
# Name simplifier
# ============================================================

def simplify_name(name):

    if "\\" in name:
        name = name.split("\\")[-1]

    name = name.replace(
        "PE_CYCLE=s32'00000000000000000000000000000001",
        "PE_CYCLE=1"
    )

    return name

# ============================================================
# Parse Yosys log
# ============================================================

modules = {}
current = None

with open(LOG_FILE, "r", encoding="utf-8", errors="ignore") as f:

    for line in f:

        # ----------------------------
        # Module header
        # ----------------------------
        m = re.match(r"^===\s+(.+?)\s+===$", line)

        if m:
            current = m.group(1)

            if current == "design hierarchy":
                current = None
                continue

            current = simplify_name(current)

            modules[current] = {
                "total_cells": 0,
                "cells": {}
            }

            continue

        if current is None:
            continue

        # ----------------------------
        # Number of cells
        # ----------------------------
        m = re.match(r"\s+Number of cells:\s+(\d+)", line)

        if m:
            modules[current]["total_cells"] = int(m.group(1))
            continue

        # ----------------------------
        # Cell type count
        # ----------------------------
        m = re.match(r"\s+([$\w\\\.]+)\s+(\d+)", line)

        if m:

            cell_type = simplify_name(m.group(1))
            count = int(m.group(2))

            modules[current]["cells"][cell_type] = count

# ============================================================
# Module Cell Count
# ============================================================

df_total = pd.DataFrame([
    {
        "module": module,
        "total_cells": data["total_cells"]
    }
    for module, data in modules.items()
])

df_total = df_total.sort_values(
    "total_cells",
    ascending=False
)

plt.figure(figsize=(12, 6))

plt.bar(
    df_total["module"],
    df_total["total_cells"]
)

plt.title("Yosys Cell Count by Module")
plt.ylabel("Number of Cells")

plt.xticks(
    rotation=75,
    ha="right"
)

plt.tight_layout()

plt.savefig(
    "./log_yosys/yosys_module_cells.png",
    dpi=200,
    bbox_inches="tight"
)

plt.show()

# ============================================================
# Cell Type Breakdown
# ============================================================

rows = []

for module, data in modules.items():

    for cell_type, count in data["cells"].items():

        rows.append({
            "module": module,
            "cell_type": cell_type,
            "count": count
        })

df_cells = pd.DataFrame(rows)

pivot = df_cells.pivot_table(
    index="module",
    columns="cell_type",
    values="count",
    fill_value=0
)

pivot = pivot.loc[df_total["module"]]

# ============================================================
# Stacked Bar Graph
# ============================================================

ax = pivot.plot(
    kind="bar",
    stacked=True,
    figsize=(18, 8)
)

plt.title("Yosys Cell Type Breakdown by Module")
plt.ylabel("Cell Count")

plt.xticks(
    rotation=75,
    ha="right"
)

# ------------------------------------------------------------
# Legend outside graph
# ------------------------------------------------------------

ax.legend(
    loc="upper left",
    bbox_to_anchor=(1.02, 1.0),
    fontsize=6,
    title="Cell Type",
    title_fontsize=8,
    frameon=True,
    ncol=1
)

# Leave space for legend
plt.tight_layout(
    rect=[0, 0, 0.78, 1]
)

plt.savefig(
    "./log_yosys/yosys_cell_breakdown.png",
    dpi=200,
    bbox_inches="tight"
)

plt.show()

# ============================================================
# Summary Table
# ============================================================

print()
print("=" * 60)
print("Module Cell Count")
print("=" * 60)

print(
    df_total.to_string(index=False)
)