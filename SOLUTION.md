# Sequential Asset Screening under Return and Tradability Constraints

## Summary

This project studies a finite-horizon sequential decision problem where candidates are screened under return and tradability constraints. The method uses an optimal-stopping framework with threshold-based policies and validates the approach through simulations and empirical back-testing.

## Relevance to SMILES-2026

The project is relevant to machine learning systems and industrial AI because it focuses on efficient decision-making under uncertainty, resource constraints, and limited review windows. These ideas are connected to resource-aware AI, reliable decision systems, and optimization-based methods for real-world applications.

## Methods

- Sequential decision-making
- Optimal stopping
- Threshold policies
- Monte Carlo simulation
- Empirical back-testing
- Python and MATLAB implementation

## Repository Contents

- `prepare_data.py`: builds the dataset
- `backtest_kpi_full.py`: runs the rolling back-test
- `figures_all_matlab.m`: generates additional figures
- `data/`: contains the prepared monthly dataset
- `requirements.txt`: Python dependencies
- `README.md`: reproduction instructions

## How to Run

```bash
pip install -r requirements.txt
python backtest_kpi_full.py
