import QtQuick
import QtQuick.Layouts
import JASP.Controls
import JASP.Widgets
import JASP

Form
{
  info: qsTr("The eJAB Analysis detects potential Type I errors (false positives) in a collection of hypothesis test results by identifying Bayes-frequentist contradictions. A contradiction occurs when a result is statistically significant (small p-value) yet the approximate objective Bayes factor (eJAB01) indicates the data actually support the null hypothesis. Such results are flagged as candidate Type I errors.")

  VariablesForm
  {
    AvailableVariablesList { name: "allVariables" }
    AssignedVariablesList  {
      name: "p"
      label: qsTr("p-value")
      singleVariable: true
      allowedColumns: ["scale"]
      info: qsTr("The column of observed p-values from each hypothesis test. Values must be strictly between 0 and 1.")
    }

    AssignedVariablesList  {
      name: "n"
      label: qsTr("Sample Size")
      singleVariable: true
      allowedColumns: ["scale", "ordinal"]
      info: qsTr("The column of sample sizes (n) used in each test. Must be greater than 1.")
    }

    AssignedVariablesList  {
      name: "q"
      label: qsTr("Test Dimension")
      singleVariable: true
      allowedColumns: ["scale", "ordinal"]
      info: qsTr("The column of test dimensions (q): the number of parameters tested simultaneously (e.g., q = 1 for a t-test, q = 2 for a 2 df chi-square). Must be at least 1.")
    }

    AssignedVariablesList  {
      name: "study_nums"
      label: qsTr("Study ID")
      singleVariable: true
      allowedColumns: ["scale"]
      info: qsTr("The column of study identifiers used to label flagged results in the output.")
    }
  }

  Group
  {
    title: qsTr("Significance Level & Left Tail Uniformity Cutoff")
    DoubleField { name: "alpha"; label: qsTr("α");  defaultValue: 0.05; max: 1; info: qsTr("The significance level for declaring a result statistically significant. Results with p ≤ α are considered significant. Default is 0.05.") }
    DoubleField { name: "up";    label: qsTr("uₚ"); defaultValue: 0.1;  max: 1; info: qsTr("The upper p-value cutoff defining the left-tail region used for calibration. Only results with p ≤ uₚ are used to estimate C\\*(α). This restricts calibration to the region where Type I errors are plausible. Default is 0.1.") }
  }

  Group
  {
    title: qsTr("C<sup>*</sup>(α) Grid Search")
    DoubleField { name: "lowerBound"; label: qsTr("Lower Bound"); defaultValue: 0;   max: 1; info: qsTr("The lower end of the grid over which C\\* is searched. Default is 0.") }
    DoubleField { name: "upperBound"; label: qsTr("Upper Bound"); defaultValue: 3.0; max: 3; info: qsTr("The upper end of the grid over which C\\* is searched. Default is 3.") }
    Slider
    {
      name: "grid_size"
      label: qsTr("Size of the Grid")
      value: 200
      vertical: false
      min: 2
      max: 10000
      decimals: 0
      info: qsTr("The number of candidate C values evaluated during the grid search. A larger grid gives a more precise estimate of C\\*(α) at the cost of computation time. Default is 200.")
    }
  }

  Group
  {
    title: qsTr("Plots")
    CheckBox {
      name: "showCalibrationPlot"
      label: qsTr("Calibration curve")
      checked: true
      info: qsTr("Plots the observed contradiction rate against α with the ideal diagonal reference. A well-calibrated C*(α) produces a curve close to the diagonal.")
    }
    CheckBox {
      name: "showZDiagnostic"
      label: qsTr("Z-diagnostic plots")
      checked: true
      info: qsTr("Displays the normal-score (Z) diagnostic for the candidate Type I errors as two plots: (1) a normal QQ-plot of Z with an OLS best-fit line; and (2) Z against candidate index with reference bands at ±2. The diagnostic U is Unif(0, 1) under left-tail uniformity, so Z = Φ⁻¹(U) is N(0, 1); candidates with |Z| > 2 fall outside the bands and are likely not Type I errors.")
    }
  }
}
