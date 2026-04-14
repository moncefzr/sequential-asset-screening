"""
backtest_kpi_full.py
====================

Full rolling-window back-test + KPI extraction for the dual-criterion
adaptive shrinking-window screening model.

CHANGES FROM ORIGINAL
---------------------
1. Column renamed: log_illiq -> log_tradability (higher = more tradable).
   This aligns the empirical variable with the theoretical model (Section 2.2)
   where eligibility requires M_i >= T_b and larger M_i means more tradable.
2. pQ threshold aligned with MATLAB: 1e-10 -> 1e-8.
3. pe gate [0.02, 0.98] retained but documented explicitly.
4. kpi_window_summary.csv is now saved (previously only printed).
5. prepare_data.py cross-reference corrected (was pointing to a non-existent .m).

HOW TO RUN
----------
python backtest_kpi_full.py

REQUIRES
--------
pip install numpy pandas scipy matplotlib

INPUT FILE
----------
data_monthly.csv   (produced by prepare_data.py)
Expected columns: date, ticker, R, log_tradability

OUTPUTS
-------
- fig_backtest_kpi.pdf / .png / .eps
- kpi_overall.csv
- kpi_window_level.csv
- kpi_window_summary.csv
- kpi_regime.csv
"""

import os
import time
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from scipy.stats import norm, nbinom, pearsonr, spearmanr
from scipy.special import roots_hermite
from scipy.integrate import quad
from scipy.interpolate import interp1d


# =============================================================================
# SETTINGS
# =============================================================================

DATA_FILE  = "data_monthly.csv"
OUTPUT_DIR = "."
DPI        = 180

# Algorithm parameters
M     = 10
Q     = 5
W0    = 5
S1    = 1
S2    = 0
WMIN  = 1
WMAX  = 20
ALPHA = 0.5

# Rolling window protocol
CAL_MONTHS  = 36
TEST_MONTHS = 12
ROLL_STEP   = 6
N_PERMS     = 50
TA_GRID     = np.linspace(-0.04, 0.06, 15)
TB_FIXED    = 0.0  # cross-sectional mean of log_tradability after demeaning

np.random.seed(42)


# =============================================================================
# CORE ANALYTICAL ENGINE
# =============================================================================

def build_model(mu_R, sig_R, mu_M, sig_M, Ta, Tb, alpha):
    a  = alpha
    dR = (Ta - mu_R) / sig_R
    dM = (Tb - mu_M) / sig_M
    pe = norm.sf(dR) * norm.sf(dM)

    vs = np.sqrt(a**2 + (1 - a)**2)

    # FIX: guard inverse Mills ratios against division by zero
    lR = norm.pdf(dR) / max(norm.sf(dR), 1e-14)
    lM = norm.pdf(dM) / max(norm.sf(dM), 1e-14)

    mu_c  = a * lR + (1 - a) * lM
    sc2   = a**2 * (1 + dR * lR - lR**2) + (1 - a)**2 * (1 + dM * lM - lM**2)
    sig_c = np.sqrt(max(sc2, 1e-12))
    s_min = a * dR + (1 - a) * dM

    def f_SgivenD(s):
        s = np.atleast_1d(np.asarray(s, dtype=float))
        out = np.zeros_like(s)
        ok = s > s_min
        if not np.any(ok):
            return float(out[0]) if out.size == 1 else out
        ss = s[ok]
        cu = ((ss - (1 - a) * dM) / a - a * ss / vs**2) * vs / (1 - a)
        cl = (dR - a * ss / vs**2) * vs / (1 - a)
        valid = cu > cl
        if np.any(valid):
            v = (1.0 / (pe * vs)) * norm.pdf(ss[valid] / vs) * (
                norm.cdf(cu[valid]) - norm.cdf(cl[valid]))
            tmp = np.zeros(ss.size)
            tmp[valid] = np.maximum(v, 0.0)
            out[ok] = tmp
        return float(out[0]) if out.size == 1 else out

    s_grid  = np.linspace(s_min, 5.0, 120)
    ps_vals = np.zeros_like(s_grid)
    for i, sg in enumerate(s_grid):
        if sg >= 4.5:
            ps_vals[i] = 0.0
        else:
            fbar, _ = quad(f_SgivenD, sg, 8.0, limit=80)
            ps_vals[i] = pe * min(fbar, 1.0)

    interp_fun = interp1d(s_grid, ps_vals, kind="linear",
                          bounds_error=False, fill_value=(ps_vals[0], 0.0))

    def p_func(s):
        if s <= s_min:
            return float(pe)
        if s >= 5.0:
            return 0.0
        return float(max(interp_fun(s), 0.0))

    return p_func, pe, mu_c, sig_c


def P_rec(p, mp, r, w, s1, s2, wmin, wmax, cache):
    if mp == 0:
        return 1.0
    if r <= 0 or r < mp:
        return 0.0
    key = (mp, r, w)
    if key in cache:
        return cache[key]
    wh   = min(w, r)
    wp   = min(w + s2, wmax)
    wm   = max(w - s1, wmin)
    ph0  = (1 - p) ** wh
    ph1  = wh * p * (1 - p) ** (wh - 1)
    phge2 = 1.0 - ph0 - ph1
    v = ph0 * P_rec(p, mp, r - wh, wp, s1, s2, wmin, wmax, cache)
    if mp == 1:
        v += ph1
    else:
        v += ph1 * P_rec(p, mp - 1, r - wh, w, s1, s2, wmin, wmax, cache)
    # FIX: threshold aligned with MATLAB (1e-8 -> consistent across files)
    if phge2 > 1e-8:
        if mp == 1:
            v += phge2
        else:
            v += phge2 * P_rec(p, mp - 1, r - wh, wm, s1, s2, wmin, wmax, cache)
    cache[key] = v
    return v


def P_total(p_func, pe, mu_c, sig_c, n, m, q, w0, s1, s2, wmin, wmax, K=8):
    x_gh, w_gh = roots_hermite(K)
    sc_q = sig_c / np.sqrt(q)
    tot  = 0.0
    for q0 in range(q, n - m + 1):
        r = n - q0
        if r < m:
            break
        pQ = nbinom.pmf(q0 - q, q, pe)
        # FIX: threshold aligned with MATLAB (was 1e-10, MATLAB uses 1e-8)
        if pQ < 1e-8:
            continue
        gh = 0.0
        for k in range(K):
            s_node = mu_c + np.sqrt(2) * sc_q * x_gh[k]
            p_node = p_func(s_node)
            cache  = {}
            gh    += w_gh[k] * P_rec(p_node, m, r, w0, s1, s2, wmin, wmax, cache)
        tot += pQ * gh / np.sqrt(np.pi)
    return tot


# =============================================================================
# EMPIRICAL SIMULATION ENGINE
# =============================================================================

def simulate_algorithm(R_seq, Trad_seq, mu_R, sig_R, mu_M, sig_M,
                       Ta, Tb, alpha, m, q, w0, s1, s2, wmin, wmax):
    """
    Simulates one run of the adaptive screening algorithm on a candidate stream.

    Parameters
    ----------
    R_seq    : array of monthly log-returns
    Trad_seq : array of log_tradability values (HIGHER = more tradable)
               Eligibility condition: Trad_seq[i] >= Tb  (above-threshold tradability)
    """
    n = len(R_seq)
    # Eligibility: return above Ta AND tradability above Tb
    D = (R_seq >= Ta) & (Trad_seq >= Tb)
    S = alpha * (R_seq - mu_R) / sig_R + (1 - alpha) * (Trad_seq - mu_M) / sig_M

    # Learning phase
    ec, bs, i = 0, [], 0
    while i < n and ec < q:
        if D[i]:
            ec += 1
            bs.append(S[i])
        i += 1
    if ec < q:
        return None

    # Screening phase
    Sstar = np.mean(bs)
    quota, w, j = m, w0, i
    while j < n and quota > 0:
        we = min(w, n - j)
        if we == 0:
            break
        H, first = 0, -1
        for k in range(j, j + we):
            if D[k] and S[k] > Sstar:
                H += 1
                if first < 0:
                    first = k
        if first >= 0:
            quota -= 1
        if H == 0:
            w = min(w + s2, wmax)
        elif H >= 2:
            w = max(w - s1, wmin)
        j += we

    return int(quota == 0)


# =============================================================================
# LOAD DATA
# =============================================================================

print("=" * 68)
print("FULL ROLLING BACK-TEST + KPI EXTRACTION")
print("=" * 68)

if not os.path.isfile(DATA_FILE):
    raise FileNotFoundError(
        f"{DATA_FILE} not found. Run prepare_data.py first.")

df = pd.read_csv(DATA_FILE, parse_dates=["date"])
df = df.sort_values(["date", "ticker"]).reset_index(drop=True)

# FIX: updated column name from log_illiq -> log_tradability
required_cols = {"date", "ticker", "R", "log_tradability"}
missing = required_cols - set(df.columns)
if missing:
    raise ValueError(
        f"Missing columns: {missing}\n"
        "If your CSV has 'log_illiq', re-run prepare_data.py to regenerate "
        "with the sign-corrected 'log_tradability' column.")

all_months  = sorted(df["date"].unique())
all_tickers = sorted(df["ticker"].unique())
n_months    = len(all_months)
n_tickers   = len(all_tickers)

print(f"Loaded observations : {len(df)}")
print(f"Number of stocks    : {n_tickers}")
print(f"Number of months    : {n_months}")
print(f"Date range          : {pd.Timestamp(all_months[0]).strftime('%Y-%m')} "
      f"to {pd.Timestamp(all_months[-1]).strftime('%Y-%m')}")
print(f"Tradability column  : log_tradability (higher = more tradable)")

month_idx  = {m: i for i, m in enumerate(all_months)}
ticker_idx = {t: i for i, t in enumerate(all_tickers)}

R_mat    = np.full((n_months, n_tickers), np.nan)
Trad_mat = np.full((n_months, n_tickers), np.nan)

for _, row in df.iterrows():
    mi = month_idx[row["date"]]
    ti = ticker_idx[row["ticker"]]
    R_mat[mi, ti]    = row["R"]
    Trad_mat[mi, ti] = row["log_tradability"]


# =============================================================================
# ROLLING BACK-TEST
# =============================================================================

print("\nRolling-window protocol")
print(f"Calibration window : {CAL_MONTHS} months")
print(f"Test window        : {TEST_MONTHS} months")
print(f"Roll step          : {ROLL_STEP} months")
print(f"Permutations       : {N_PERMS} per window")
print(f"T_a grid           : {TA_GRID[0]:.3f} to {TA_GRID[-1]:.3f} ({len(TA_GRID)} pts)")
print(f"T_b fixed          : {TB_FIXED:.3f} (cross-sectional mean of log_tradability)")

win_starts    = list(range(0, n_months - CAL_MONTHS - TEST_MONTHS + 1, ROLL_STEP))
n_wins        = len(win_starts)
emp_rate      = np.full((n_wins, len(TA_GRID)), np.nan)
ana_rate      = np.full((n_wins, len(TA_GRID)), np.nan)
n_cands_vec   = np.full(n_wins, np.nan)
test_end_dates = []

t0 = time.time()

for w_idx, t_cal_start in enumerate(win_starts):
    t_cal_end    = t_cal_start + CAL_MONTHS
    t_test_start = t_cal_end
    t_test_end   = t_test_start + TEST_MONTHS

    end_date = pd.Timestamp(all_months[min(t_test_end - 1, n_months - 1)])
    test_end_dates.append(end_date)

    # Calibration moments
    R_cal    = R_mat[t_cal_start:t_cal_end, :].ravel()
    Trad_cal = Trad_mat[t_cal_start:t_cal_end, :].ravel()
    R_cal    = R_cal[~np.isnan(R_cal)]
    Trad_cal = Trad_cal[~np.isnan(Trad_cal)]

    mu_R_e  = float(np.mean(R_cal))
    sig_R_e = float(np.std(R_cal))
    mu_M_e  = float(np.mean(Trad_cal))
    sig_M_e = float(np.std(Trad_cal))

    # Test candidates (all stock-month obs in test block, pooled)
    R_test    = R_mat[t_test_start:t_test_end, :]
    Trad_test = Trad_mat[t_test_start:t_test_end, :]
    valid     = ~np.isnan(R_test) & ~np.isnan(Trad_test)

    R_cands    = R_test[valid]
    Trad_cands = Trad_test[valid]
    n_cands    = len(R_cands)
    n_cands_vec[w_idx] = n_cands

    if n_cands < M + Q + 10:
        continue

    for ta_idx, Ta in enumerate(TA_GRID):
        Tb = TB_FIXED

        # Empirical: N_PERMS independent random orderings of the pooled panel
        results = []
        for _ in range(N_PERMS):
            perm = np.random.permutation(n_cands)
            out  = simulate_algorithm(
                R_cands[perm], Trad_cands[perm],
                mu_R_e, sig_R_e, mu_M_e, sig_M_e,
                Ta, Tb, ALPHA, M, Q, W0, S1, S2, WMIN, WMAX)
            if out is not None:
                results.append(out)

        if len(results) >= max(5, N_PERMS // 2):
            emp_rate[w_idx, ta_idx] = np.mean(results)

        # Analytical: Gaussian plug-in using calibration moments
        # pe gate [0.02, 0.98]: skip near-degenerate regimes where the
        # Gaussian model's CLT approximation for S* breaks down or pe -> 0/1
        # makes the negative-binomial sum numerically trivial.
        pf, pe, mu_c, sig_c = build_model(
            mu_R_e, sig_R_e, mu_M_e, sig_M_e, Ta, Tb, ALPHA)
        if 0.02 <= pe <= 0.98:
            ana_rate[w_idx, ta_idx] = P_total(
                pf, pe, mu_c, sig_c, n_cands, M, Q, W0, S1, S2, WMIN, WMAX)

    elapsed = time.time() - t0
    print(f"Window {w_idx+1:2d}/{n_wins}: end={end_date.strftime('%Y-%m')}  "
          f"n_cands={n_cands:3d}  elapsed={elapsed:7.1f}s")

print("\nBack-test finished.")


# =============================================================================
# OVERALL KPIs
# =============================================================================

mask    = np.isfinite(emp_rate) & np.isfinite(ana_rate)
emp_all = emp_rate[mask]
ana_all = ana_rate[mask]

if len(emp_all) < 5:
    raise RuntimeError("Not enough valid pairs to compute KPIs.")

rmse  = np.sqrt(np.mean((emp_all - ana_all) ** 2))
mae   = np.mean(np.abs(emp_all - ana_all))
bias  = np.mean(emp_all - ana_all)
r_val, _ = pearsonr(ana_all, emp_all)
slope, intercept = np.polyfit(ana_all, emp_all, 1)
r2    = r_val ** 2

overall_df = pd.DataFrame({
    "RMSE":              [rmse],
    "MAE":               [mae],
    "Bias_emp_minus_ana":[bias],
    "Pearson_r":         [r_val],
    "Slope":             [slope],
    "Intercept":         [intercept],
    "R2":                [r2],
    "N_pairs":           [len(emp_all)]
})

print("\n=== OVERALL KPIs ===")
print(overall_df.to_string(index=False))


# =============================================================================
# WITHIN-WINDOW KPIs
# =============================================================================

window_rows = []
for w in range(n_wins):
    e  = emp_rate[w, :]
    a  = ana_rate[w, :]
    ok = np.isfinite(e) & np.isfinite(a)
    if np.sum(ok) < 5:
        continue
    rho_s, _     = spearmanr(a[ok], e[ok])
    emp_is_mono  = bool(np.all(np.diff(e[ok]) <= 1e-10))
    ana_is_mono  = bool(np.all(np.diff(a[ok]) <= 1e-10))
    both_mono    = emp_is_mono and ana_is_mono
    row_bias     = np.mean(e[ok] - a[ok])
    row_rmse     = np.sqrt(np.mean((e[ok] - a[ok]) ** 2))
    window_rows.append({
        "window_id":      w + 1,
        "test_end_date":  pd.Timestamp(test_end_dates[w]).strftime("%Y-%m"),
        "n_cands":        int(n_cands_vec[w]),
        "spearman_rho":   rho_s,
        "emp_monotone":   int(emp_is_mono),
        "ana_monotone":   int(ana_is_mono),
        "both_monotone":  int(both_mono),
        "window_bias":    row_bias,
        "window_rmse":    row_rmse
    })

window_df = pd.DataFrame(window_rows)

summary_window_df = pd.DataFrame({
    "Mean_Spearman_rho":      [window_df["spearman_rho"].mean()],
    "Median_Spearman_rho":    [window_df["spearman_rho"].median()],
    "Pct_windows_rho_gt_0_8": [100 * np.mean(window_df["spearman_rho"] > 0.8)],
    "Pct_empirical_monotone": [100 * window_df["emp_monotone"].mean()],
    "Pct_analytical_monotone":[100 * window_df["ana_monotone"].mean()],
    "Pct_both_monotone":      [100 * window_df["both_monotone"].mean()],
    "N_windows_used":         [len(window_df)]
})

print("\n=== WITHIN-WINDOW KPIs ===")
print(summary_window_df.to_string(index=False))


# =============================================================================
# REGIME-BY-REGIME KPIs
# =============================================================================

def assign_regime(end_date):
    d = pd.Timestamp(end_date)
    if d <= pd.Timestamp("2010-12-31"):
        return "Crisis/Post-crisis"
    elif d <= pd.Timestamp("2019-12-31"):
        return "2011-2019"
    else:
        return "COVID/Rate-shock"

regime_rows = []
for reg in ["Crisis/Post-crisis", "2011-2019", "COVID/Rate-shock"]:
    idx = [i for i, d in enumerate(test_end_dates) if assign_regime(d) == reg]
    if not idx:
        continue
    e  = emp_rate[idx, :]
    a  = ana_rate[idx, :]
    ok = np.isfinite(e) & np.isfinite(a)
    if np.sum(ok) < 5:
        continue
    e_all, a_all = e[ok], a[ok]
    rmse_r = np.sqrt(np.mean((e_all - a_all) ** 2))
    mae_r  = np.mean(np.abs(e_all - a_all))
    bias_r = np.mean(e_all - a_all)
    r_r    = pearsonr(a_all, e_all)[0] if len(e_all) >= 3 else np.nan
    regime_rows.append({
        "Regime":           reg,
        "RMSE":             rmse_r,
        "MAE":              mae_r,
        "Bias_emp_minus_ana": bias_r,
        "Pearson_r":        r_r,
        "N_pairs":          len(e_all)
    })

regime_df = pd.DataFrame(regime_rows)
print("\n=== REGIME-BY-REGIME KPIs ===")
print(regime_df.to_string(index=False) if len(regime_df) else "No valid rows.")


# =============================================================================
# SAVE ALL KPI TABLES
# =============================================================================

os.makedirs(OUTPUT_DIR, exist_ok=True)
overall_df.to_csv(os.path.join(OUTPUT_DIR, "kpi_overall.csv"),         index=False)
window_df.to_csv( os.path.join(OUTPUT_DIR, "kpi_window_level.csv"),    index=False)
regime_df.to_csv( os.path.join(OUTPUT_DIR, "kpi_regime.csv"),          index=False)
# FIX: window-level summary was computed but never saved; now it is.
summary_window_df.to_csv(
    os.path.join(OUTPUT_DIR, "kpi_window_summary.csv"), index=False)

print("\nSaved:")
for f in ["kpi_overall.csv", "kpi_window_level.csv",
          "kpi_window_summary.csv", "kpi_regime.csv"]:
    print(f"  {os.path.join(OUTPUT_DIR, f)}")


# =============================================================================
# FIGURE
# =============================================================================

emp_mean = np.nanmean(emp_rate, axis=0)
ana_mean = np.nanmean(ana_rate, axis=0)
emp_q05  = np.nanpercentile(emp_rate,  5, axis=0)
emp_q95  = np.nanpercentile(emp_rate, 95, axis=0)

xfit = np.linspace(np.nanmin(ana_all), np.nanmax(ana_all), 200)
yfit = slope * xfit + intercept

plt.rcParams.update({"font.family": "serif", "font.size": 12})
fig, axes = plt.subplots(1, 2, figsize=(13, 5), constrained_layout=True)

ax = axes[0]
ax.fill_between(TA_GRID, emp_q05, emp_q95,
                color="#7ea1d2", alpha=0.65, label="Empirical 90% band")
ax.plot(TA_GRID, emp_mean, "o-", color="#1f77b4", lw=2.2, ms=8,
        label="Empirical rate (mean)")
ax.plot(TA_GRID, ana_mean, "s--", color="#d62728", lw=2.2, ms=8,
        label=r"Analytical $P_{\mathrm{total}}$ (mean)")
ax.set_xlabel(r"$T_a$", fontsize=16)
ax.set_ylabel("Shortlist completion rate", fontsize=16)
ax.set_xlim(TA_GRID.min() - 0.005, TA_GRID.max() + 0.005)
ax.set_ylim(0.74, 1.01)
ax.grid(True, alpha=0.3)
ax.legend(frameon=True, fontsize=12, loc="lower left")

ax = axes[1]
ax.scatter(ana_all, emp_all, color="gray", s=40, alpha=0.9,
           label=fr"Rolling window ($n={len(emp_all)}$ pts)")
mn = min(np.nanmin(ana_all), np.nanmin(emp_all))
mx = max(np.nanmax(ana_all), np.nanmax(emp_all))
ax.plot([mn, mx], [mn, mx], "k--", lw=2, label="Perfect calibration")
ax.plot(xfit, yfit, color="#d62728", lw=2.5,
        label=fr"Linear fit (slope={slope:.2f}, $r$={r_val:.2f})")
ax.set_xlabel(r"$P_{\mathrm{total}}$", fontsize=16)
ax.set_ylabel("Empirical completion rate", fontsize=16)
ax.set_xlim(mn, mx)
ax.set_ylim(mn, mx)
ax.grid(True, alpha=0.3)
ax.legend(frameon=True, fontsize=12, loc="lower right")

for ext in ["pdf", "png", "eps"]:
    path = os.path.join(OUTPUT_DIR, f"fig_backtest_kpi.{ext}")
    kw   = {"format": "eps"} if ext == "eps" else {}
    plt.savefig(path, dpi=DPI, bbox_inches="tight", **kw)
    print(f"Saved: {path}")

plt.close(fig)
