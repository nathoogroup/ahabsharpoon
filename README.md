# Ahab's Harpoon

A JASP module for detecting candidate Type I errors in collections of hypothesis test results using Bayes-frequentist contradictions.

## What it does

The module identifies results where frequentist and Bayesian evidence point in opposite directions: the p-value leads to rejecting H0, but the approximate objective Bayes factor (eJAB01) indicates the data actually support H0. Such contradictions are flagged as candidate Type I errors.

For each result the module:
1. Computes the eJAB01 Bayes factor from the p-value, sample size, and test dimension
2. Estimates an optimal threshold C*(α) via a calibrated grid search
3. Flags any result with p < α and eJAB01 > C*(α) as a candidate Type I error
4. Produces calibration plots, a diagnostic QQ-plot, and a data summary plot

## Input data

Each row should represent one hypothesis test result with columns for:
- **p-value** — the observed p-value (strictly between 0 and 1)
- **n** — sample size (> 1)
- **q** — test dimension (number of parameters tested; ≥ 1)
- **Study ID** — an identifier for each result

An example dataset (the Reproducibility Project: Psychology) is included as `inst/data/rpp_data.csv`.

## Usage

1. Open JASP and load the module as a development module
2. Load your dataset (or open `rpp_analysis.jasp` for a pre-configured example)
3. Open **Ahab's Harpoon → eJAB Analysis**
4. Assign your p-value, sample size, test dimension, and study ID columns
5. Adjust α and other parameters as needed

## Reference

Nathoo, F. S., Velidi, P., Wei, Z., & Strasdin, E. (2026). *Detecting Type I errors through Bayes/NHST conflict using eJAB*. Unpublished manuscript.

## License

GPL (>= 2)
