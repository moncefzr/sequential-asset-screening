"""
prepare_data.py
===============
Downloads real financial data from Yahoo Finance and saves a clean CSV
ready for backtest_kpi_full.py.

HOW TO RUN:
    pip install yfinance pandas numpy
    python prepare_data.py

WHAT IT PRODUCES:
    data_monthly.csv  -- monthly returns + log-tradability
                         one row per (stock, month)

COLUMNS IN data_monthly.csv:
    ticker           -- stock ticker symbol
    date             -- last trading day of month (YYYY-MM-DD)
    R                -- monthly log-return  = log(P_t / P_{t-1})
    log_tradability  -- tradability score = -log_Amihud_demeaned
                        Sign convention: HIGHER values = MORE tradable,
                        consistent with M_i in the theoretical model (Section 2.2)
                        where eligibility requires M_i >= T_b.

LIQUIDITY PROXY NOTE:
    The raw measure is a monthly Amihud-inspired illiquidity ratio:
        illiq_it = |R_it| / (monthly_dollar_volume_it)
    This is NOT the standard daily Amihud measure averaged over trading days;
    it is a monthly proxy computed from the monthly |R| and the sum of daily
    dollar volumes within the month. The proxy is log-transformed,
    cross-sectionally demeaned per month, then NEGATED so that higher values
    denote higher tradability.

STOCKS:
    30 long-history S&P 500 constituents spanning multiple sectors.

PERIOD:
    January 2005 -- December 2023 (227 usable months after return differencing)
"""

import yfinance as yf
import pandas as pd
import numpy as np
import os

# ---------------------------------------------------------------------------
#  SETTINGS
# ---------------------------------------------------------------------------

TICKERS = [
    'AAPL', 'MSFT', 'INTC', 'IBM', 'TXN',
    'JPM',  'BAC',  'GS',   'WFC', 'AXP',
    'JNJ',  'PFE',  'MRK',  'ABT', 'MDT',
    'PG',   'KO',   'PEP',  'MCD', 'WMT',
    'XOM',  'CVX',  'COP',  'SLB', 'HAL',
    'GE',   'HON',  'CAT',  'MMM', 'BA'
]

START_DATE = '2005-01-01'
END_DATE   = '2023-12-31'
OUTPUT_CSV = 'data_monthly.csv'

# ---------------------------------------------------------------------------
#  DOWNLOAD DAILY DATA
# ---------------------------------------------------------------------------

print("Downloading daily data from Yahoo Finance...")
print(f"  Tickers : {len(TICKERS)} stocks")
print(f"  Period  : {START_DATE} to {END_DATE}")

raw = yf.download(TICKERS, start=START_DATE, end=END_DATE,
                  auto_adjust=True, progress=True)

close  = raw['Close']
volume = raw['Volume']

min_obs = int(0.90 * len(close))
close   = close.dropna(axis=1, thresh=min_obs)
volume  = volume[close.columns]
tickers_ok = list(close.columns)

print(f"\n  Tickers retained : {len(tickers_ok)}")
print(f"  Date range       : {close.index[0].date()} to {close.index[-1].date()}")

# ---------------------------------------------------------------------------
#  COMPUTE MONTHLY RETURNS AND TRADABILITY PROXY
# ---------------------------------------------------------------------------

print("\nComputing monthly aggregates...")

close_m  = close.resample('ME').last()
volume_m = volume.resample('ME').sum()

# Monthly log-returns
log_ret = np.log(close_m / close_m.shift(1)).iloc[1:]

# Monthly Amihud-inspired illiquidity proxy: |R_it| / (monthly dollar volume)
# NOTE: monthly proxy, not the standard daily-Amihud aggregated over days.
abs_ret    = log_ret.abs()
dv         = (volume_m * close_m).iloc[1:]
amihud     = abs_ret / (dv + 1e-10)
log_amihud = np.log(amihud + 1e-15)

def winsorise(df, q_low=0.01, q_high=0.99):
    lo = df.quantile(q_low)
    hi = df.quantile(q_high)
    return df.clip(lower=lo, upper=hi, axis=1)

log_ret    = winsorise(log_ret)
log_amihud = winsorise(log_amihud)

# Cross-sectional demeaning per month
log_amihud_dm = log_amihud.subtract(log_amihud.mean(axis=1), axis=0)

# FIX (sign): negate so that higher values = more tradable, consistent with
# the model where M_i >= T_b selects the most tradable candidates.
log_tradability = -log_amihud_dm

# ---------------------------------------------------------------------------
#  STACK TO LONG FORMAT
# ---------------------------------------------------------------------------

print("Stacking to long format...")

df_ret  = log_ret.stack().rename('R')
df_trad = log_tradability.stack().rename('log_tradability')

data = pd.concat([df_ret, df_trad], axis=1).reset_index()
data.columns = ['date', 'ticker', 'R', 'log_tradability']
data = data.dropna()
data['date'] = data['date'].dt.strftime('%Y-%m-%d')
data = data.sort_values(['ticker', 'date']).reset_index(drop=True)

# ---------------------------------------------------------------------------
#  SUMMARY
# ---------------------------------------------------------------------------

print(f"\n  Total obs   : {len(data)}")
print(f"  Stocks      : {data['ticker'].nunique()}")
print(f"  Months      : {data['date'].nunique()}")
print(f"  Date range  : {data['date'].min()} to {data['date'].max()}")
print(f"\n  R              mean={data['R'].mean():.4f}  std={data['R'].std():.4f}")
print(f"  log_tradab.    mean={data['log_tradability'].mean():.4f}  "
      f"std={data['log_tradability'].std():.4f}")

data.to_csv(OUTPUT_CSV, index=False)
print(f"\nSaved: {OUTPUT_CSV}  ({os.path.getsize(OUTPUT_CSV)//1024} KB)")
print("Column 'log_tradability': higher = more tradable (sign-corrected).")
print("Next step: run backtest_kpi_full.py")
