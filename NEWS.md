# jaspAhabsHarpoon 0.1

* Initial release. Implements the eJAB analysis: computes the eJAB01
  approximate objective Bayes factor for each NHST result, estimates a
  calibrated threshold C* via integrated squared deviation, and flags
  Bayes/NHST contradictions as candidate Type I errors.
* Outputs: summary table, candidate-error table, calibration curve, and the
  Z-diagnostic plots (normal QQ-plot and Z-vs-index plot, flagging candidates
  with |Z| > 2).
* Bundled example datasets: Reproducibility Project: Psychology
  (`inst/data/rpp_data.csv`) and Reproducibility Project: Cancer Biology
  (`inst/data/rpcb_data.csv`), with pre-configured analyses in
  `inst/examples/`.
