# Sequential Asset Screening under Return and Tradability Constraints

> Replication code for the paper:  
> **"Sequential Asset Screening under Return and Tradability Constraints:
> An Optimal-Stopping Framework with Exact Recursion and Adaptive Window Policies"**  
> *Submitted to the European Journal of Operational Research (EJOR)*

---

## Overview

This repository contains all code needed to reproduce the figures, tables,
and back-test results reported in the paper.  
The paper develops a finite-horizon sequential screening framework in which
candidates must satisfy both a **return threshold** and a **tradability threshold**
before they can be shortlisted, while at most one confirmation is permitted per
review window.

---

## Repository structure

```
.
├── prepare_data.py                   # Step 1 — download & build data_monthly.csv
├── backtest_kpi_full.py              # Step 2 — rolling back-test, Figure 4, KPI tables
├── figures_all_matlab_jsac_style.m   # Step 3 — Figures 1–3 and Table 6 (MATLAB)
├── data/
│   └── data_monthly.csv             # Pre-built CSV (30 S&P 500 constituents, 2005–2023)
├── requirements.txt                  # Python dependencies
└── README.md
```

---

## Figure and table mapping

| Output | Script | Paper location |
|--------|--------|----------------|
| `fig1_val_w0`        | `figures_all_matlab_jsac_style.m` | Figure 1(a) — P_total vs w0 |
| `fig2_val_alpha`     | `figures_all_matlab_jsac_style.m` | Figure 1(b) — P_total vs α (bar chart) |
| `fig3_val_vs_n`      | `figures_all_matlab_jsac_style.m` | Figure 1(c) — P_total vs n |
| `fig4_val_vs_m`      | `figures_all_matlab_jsac_style.m` | Figure 2(a) — P_total vs m |
| `fig5_val_condpdf`   | `figures_all_matlab_jsac_style.m` | Figure 2(b) — Conditional score density |
| `fig6_val_benchmark` | `figures_all_matlab_jsac_style.m` | Figure 2(c) — Benchmark distribution |
| `fig7_app_policy`    | `figures_all_matlab_jsac_style.m` | Figure 3(a) — Policy comparison |
| `fig8_app_w0`        | `figures_all_matlab_jsac_style.m` | Figure 3(b) — P_total vs w0 (4 contexts) |
| `fig9_app_alpha`     | `figures_all_matlab_jsac_style.m` | Figure 3(c) — P_total vs α (4 contexts) |
| `fig10_robust_w0` + Table 6 summary | `figures_all_matlab_jsac_style.m` | Table 6 — Heavy-tail robustness |
| `fig_backtest_kpi.pdf` | `backtest_kpi_full.py` | Figure 4 — Rolling back-test |
| `kpi_overall.csv`    | `backtest_kpi_full.py` | Table 7 (overall KPIs) |
| `kpi_window_summary.csv` | `backtest_kpi_full.py` | Table 7 (Spearman / monotonicity rows) |
| `kpi_regime.csv`     | `backtest_kpi_full.py` | Table 8 — Regime KPIs |

---

## How to reproduce

### Requirements

- **Python** ≥ 3.9
- **MATLAB** R2020b or later (for figures 1–3 and Table 6)

### Step 0 — Install Python dependencies

```bash
pip install -r requirements.txt
```

### Step 1 — Build the data (optional — pre-built CSV is included)

```bash
python prepare_data.py
```

Downloads monthly returns and tradability proxies for 30 long-history
S&P 500 constituents (Feb 2005 – Dec 2023) from Yahoo Finance and writes
`data/data_monthly.csv`.

> **Tradability convention:** `log_tradability = −log_Amihud_demeaned`.
> Higher values indicate higher tradability, consistent with the model's
> eligibility condition M_i ≥ T_b (Section 2.2 of the paper).

### Step 2 — Run the rolling back-test (Python)

```bash
python backtest_kpi_full.py
```

Produces `fig_backtest_kpi.pdf`, `fig_backtest_kpi.png`, and the four KPI
CSV files. Runtime: approximately 15–30 minutes depending on hardware
(N_PERMS = 50, 30 rolling windows, 15 threshold values each).

### Step 3 — Generate all other figures and Table 6 (MATLAB)

Open MATLAB, navigate to this folder, and run:

```matlab
figures_all_matlab_jsac_style
```

All figures (fig1–fig10) are saved as `.eps` and `.fig` in the current
directory. Table 6 summary statistics are printed to the MATLAB console.
Runtime: approximately 20–40 minutes (N_MC = 20,000 trials per figure).

---

## Calibrated application contexts

| Context | µR | σR | µM | σM | Ta | Tb | n | m | pe |
|---------|----|----|----|----|----|----|---|---|----|
| Large-Cap Equity | 0.008 | 0.055 | 0.000 | 0.650 | 0.020 | 0.300 | 120 | 10 | 0.133 |
| Small-Cap Equity | 0.010 | 0.075 | 0.400 | 0.800 | 0.030 | 0.600 | 150 | 12 | 0.158 |
| High-Yield Credit | 0.004 | 0.025 | −0.300 | 0.500 | 0.008 | −0.100 | 150 | 10 | 0.150 |
| Liq-Stressed | 0.002 | 0.080 | 0.000 | 0.500 | 0.010 | 0.400 | 120 | 10 | 0.098 |

---

## Notes on the empirical back-test

- The candidate pool for each test window consists of all valid (stock, month)
  observations in the 12-month test block, **pooled and randomly permuted**
  (50 orderings per window). This approximates sequential arrival under
  non-exchangeable real data, as discussed in Section 6.5 of the paper.
- The analytical P_total is evaluated using Gaussian plug-in moments
  estimated from the 36-month calibration window. The comparison is
  a **directional validity check**, not a structural calibration.
- The liquidity proxy is a **monthly** Amihud-inspired ratio
  (|R_it| / monthly dollar volume), not the standard daily Amihud
  measure aggregated over trading days.

---

## Citation

```bibtex
@article{,
  title   = {Sequential Asset Screening under Return and Tradability Constraints:
             An Optimal-Stopping Framework with Exact Recursion and Adaptive Window Policies},
  author  = {},
  journal = {European Journal of Operational Research},
  year    = {},
  note    = {Under review}
}
```

---

## License

MIT License. See `LICENSE` for details.
