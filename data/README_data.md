# data_monthly.csv

Pre-built CSV included for convenience. To regenerate from scratch, run:

```bash
python prepare_data.py
```

## Columns

| Column | Description |
|--------|-------------|
| `ticker` | Stock ticker symbol |
| `date` | Last trading day of the month (YYYY-MM-DD) |
| `R` | Monthly log-return: log(P_t / P_{t-1}) |
| `log_tradability` | Tradability proxy: −log_Amihud_demeaned. **Higher = more tradable.** |

## Coverage

- **Stocks:** 30 long-history S&P 500 constituents (see `prepare_data.py` for full list)
- **Period:** February 2005 – December 2023 (227 months)
- **Observations:** 6,810 stock-month rows

## Tradability sign convention

`log_tradability = −log(|R| / dollar_volume)`, cross-sectionally demeaned per month,
then negated. The negation ensures that **larger values mean higher tradability**,
consistent with the theoretical model (Section 2.2) where eligibility requires
M_i ≥ T_b.

## Source

Downloaded from Yahoo Finance via `yfinance`. The liquidity proxy is a **monthly**
Amihud-inspired ratio, not the standard daily Amihud (2002) measure.
