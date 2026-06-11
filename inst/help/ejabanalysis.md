eJAB Analysis
===

The eJAB Analysis detects potential Type I errors (false positives) in a collection of hypothesis test results by identifying Bayes-frequentist contradictions. A contradiction occurs when frequentist and Bayesian evidence point in opposite directions: the p-value leads you to reject H<sub>0</sub>, but the Bayes factor indicates the data actually support H<sub>0</sub>. Such contradictions are candidate Type I errors: results that are statistically significant but where the underlying evidence does not warrant that conclusion.

The method works as follows. For each result, an approximate objective Bayes factor (eJAB01) is computed from the p-value, sample size, and test dimension. eJAB01 values less than 1 indicate evidence in favour of H<sub>1</sub> (consistent with rejecting H<sub>0</sub>), while values greater than 1 indicate evidence in favour of H<sub>0</sub>. Values above 3 are considered moderate evidence for H<sub>0</sub>, and above 10 strong evidence. An optimal threshold C*(&alpha;) is then estimated by calibration, and any result with p &le; &alpha; and eJAB01 &gt; C*(&alpha;) is flagged as a candidate Type I error.

### Input
-------

#### Assignment Box
- **p-value**: The column of observed p-values from each hypothesis test. Values must be strictly between 0 and 1.
- **Sample Size**: The column of sample sizes (n) used in each test. Must be greater than 1.
- **Test Dimension**: The column of test dimensions (q), i.e., the number of parameters tested simultaneously (e.g., q = 1 for a t-test, q = 2 for a 2 df chi-square). Must be at least 1.
- **Study ID**: The column of study identifiers used to label flagged results in the output.

#### Significance Level &amp; Left Tail Uniformity Cutoff
- **&alpha;**: The significance level for declaring a result statistically significant. Default is 0.05.
- **u<sub>p</sub>**: The upper p-value cutoff defining the left-tail region used for calibration. Only results with p &le; u<sub>p</sub> are used to estimate C*(&alpha;). This restricts calibration to the region where Type I errors are plausible. Default is 0.1.

#### C*(&alpha;) Grid Search
- **Lower Bound**: The lower end of the grid over which C* is searched. Default is 0.
- **Upper Bound**: The upper end of the grid over which C* is searched. Default is 3.
- **Size of the Grid**: The number of candidate C values evaluated during the grid search. A larger grid gives a more precise estimate of C*(&alpha;) at the cost of computation time. Default is 200.

#### Plots
- **Calibration curve**: Plots the observed contradiction rate against &alpha; with the ideal diagonal reference line. A well-calibrated C*(&alpha;) produces a curve close to the diagonal.
- **Z-diagnostic plots**: Displays the normal-score (Z) diagnostic for the candidate Type I errors as two plots: a normal QQ-plot of $$Z$$ and a plot of $$Z$$ against candidate index with reference bands at $$\pm 2$$.

### Output
-------

#### eJAB Summary
- **C*(&alpha;)**: The estimated optimal threshold at the selected &alpha; level. Results with p &le; &alpha; and eJAB01 &gt; C*(&alpha;) are flagged as candidate Type I errors.
- **Objective**: The value of the calibration objective function evaluated at C*(&alpha;). Smaller values indicate a better-calibrated threshold.
- **Candidates**: The number of results flagged as candidate Type I errors.
- **Total**: The total number of valid results analysed.

#### Candidate Type I Errors
A table listing each result flagged as a potential Type I error, with columns:
- **Study ID**: The identifier of the flagged study.
- **p-value**: The observed p-value.
- **n**: The sample size.
- **q**: The test dimension.
- **eJAB01**: The approximate objective Bayes factor. Values greater than 1 indicate the data favour H<sub>0</sub>; values greater than 3 are considered moderate evidence for H<sub>0</sub>.
- **eJAB10**: The reciprocal Bayes factor, $$\text{eJAB10} = 1 / \text{eJAB01}$$. Values greater than 1 indicate evidence against H<sub>0</sub>.
- **Z**: The normal-score diagnostic $$Z = \Phi^{-1}(U)$$ for the candidate (blank when $$U$$ is exactly 0 or 1).
- **Outside &plusmn;2**: Whether the candidate falls outside the $$\pm 2$$ bands ($$|Z| > 2$$). These rows are shown in red in the Z-diagnostic plots and are likely **not** Type I errors.

#### Calibration Curve
Shows the observed proportion of contradictions as a function of &alpha; alongside the ideal diagonal reference (dashed grey). A well-calibrated C*(&alpha;) produces a curve close to the diagonal.

#### Z-Diagnostic Normal QQ-Plot
The candidate diagnostic $$U_i$$ is Uniform(0, 1) under the left-tail uniformity assumption, so its normal score $$Z_i = \Phi^{-1}(U_i)$$ is $$N(0, 1)$$. This is a normal QQ-plot of the $$Z_i$$ with an ordinary-least-squares best-fit line (grey, dashed); because C* is estimated, the 45-degree line is inappropriate, so the fitted line is used instead. No probability bands are drawn: under the null the points should fall close to a straight line. Points with $$|Z_i| > 2$$ are coloured red.

#### Z-Diagnostic vs Index
Each candidate's $$Z_i$$ is plotted against its index, with flat reference bands at $$\pm 2$$ (about 95% of an $$N(0, 1)$$ distribution lies within). Candidates with $$|Z_i| > 2$$ fall outside the bands, are coloured red, and are flagged as likely **not** Type I errors.

### References
-------
- Nathoo, F. S., Velidi, P., Wei, Z., &amp; Strasdin, E. (2026). *Detecting Type I errors through Bayes/NHST conflict using eJAB*.
- Open Science Collaboration (2015). Estimating the reproducibility of psychological science. *Science*, 349(6251), aac4716.

### R-packages
---
- ejabT1E
- ggplot2
- jaspGraphs

### Example
---
- For the Reproducibility Project: Psychology dataset, go to `Open` --&gt; `Recent Files` --&gt; `rpp_analysis.jasp`.
