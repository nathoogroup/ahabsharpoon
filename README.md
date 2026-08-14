# jaspAhabsHarpoon

A JASP module for detecting candidate Type I errors in collections of hypothesis test results using Bayes/NHST contradictions.

## What it does

The module identifies results where frequentist and Bayesian evidence point in opposite directions: the p-value leads to rejecting H0, but the approximate objective Bayes factor (eJAB01) indicates the data actually support H0. Such contradictions are flagged as candidate Type I errors.

For each result the module:
1. Computes the eJAB01 Bayes factor from the p-value, sample size, and test dimension
2. Estimates an optimal threshold C*(α) via a calibrated grid search
3. Flags any result with p < α and eJAB01 > C*(α) as a candidate Type I error
4. Produces a calibration curve and the Z-diagnostic plots (normal QQ-plot and Z-vs-index plot)

## Input data

Each row should represent one hypothesis test result with columns for:
- **p-value** — the observed p-value (strictly between 0 and 1)
- **n** — sample size (> 1)
- **q** — test dimension (number of parameters tested; ≥ 1)
- **Study ID** — an identifier for each result

Two example datasets are bundled, both sharing this schema:

- `inst/data/rpp_data.csv`: Reproducibility Project: Psychology. 133 original test results, namely those in the project's audit file for which `p`, `n` and `q` could all be extracted; 123 are significant at α = 0.05. Open Science Collaboration (2015), *Science* 349:aac4716.
- `inst/data/rpcb_data.csv`: Reproducibility Project: Cancer Biology. 132 pre-clinical effects, one row per effect-level test with no aggregation over repeatedly replicated effects; 113 are significant at α = 0.05. Errington et al. (2021), *eLife* 10:e71601.

Both files are the broad extracts, carrying every row with usable `(p, n, q)`. The accompanying paper analyses narrower subsets of the same two projects (94 RPP studies, 112 RPCB effects after any-successful-replication aggregation) because scoring the rule against replication outcomes requires an outcome column these files do not include.

Pre-configured analyses live in `inst/examples/`:

- `inst/examples/rpp_analysis.jasp`
- `inst/examples/rpcb_analysis.jasp`

## Usage

1. Open JASP and load the module as a development module
2. Open one of the example `.jasp` files in `inst/examples/`, or load your own dataset
3. Open **Ahab's Harpoon → eJAB Analysis**
4. Assign your p-value, sample size, test dimension, and study ID columns
5. Adjust α and other parameters as needed

## Reference

Strasdin, E., Velidi, P., Wei, Z., & Nathoo, F. S. (2026). *Ahab's Harpoon: Predicting Type I Errors with Generalized Approximate Objective Bayes Factors*. Manuscript in preparation, Department of Mathematics and Statistics, University of Victoria.

## License

Code: GPL (>= 2). Bundled datasets retain their upstream licenses; see `inst/data/LICENSE` for details (RPP: CC0 1.0; RPCB: CC BY 4.0).
