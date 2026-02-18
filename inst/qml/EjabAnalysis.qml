import QtQuick
import QtQuick.Layouts
import JASP.Controls
import JASP.Widgets
import JASP

Form
{
  VariablesForm
  {
    AvailableVariablesList { name: "allVariables" }
    AssignedVariablesList  {
      name: "p"
      label: qsTr("p-value")
      singleVariable: true
      allowedColumns: ["scale"]
    }

    AssignedVariablesList  {
      name: "n"
      label: qsTr("Sample Size")
      singleVariable: true
      allowedColumns: ["scale"]
    }

    AssignedVariablesList  {
      name: "q"
      label: qsTr("Test Dimension")
      singleVariable: true
      allowedColumns: ["scale"]
    }

    AssignedVariablesList  {
      name: "study_nums"
      label: qsTr("Study ID")
      singleVariable: true
      allowedColumns: ["scale"]
    }
  }

  Group{
      title: qsTr("Significance Level & Left Tail Uniformity Cutoff")
      DoubleField { name: "alpha"; label: qsTr("α"); defaultValue: 0.05 ; max: 1; decimals: 2}
      DoubleField { name: "up"; label: qsTr("up"); defaultValue: 0.1 ; max: 1; decimals: 2}
  }

  Group
  {
    title: qsTr("C*(α) Grid Search")
      DoubleField { name: "lowerBound"; label: qsTr("Lower Bound"); defaultValue: 0 ; max: 1; decimals: 2}
      DoubleField { name: "upperBound"; label: qsTr("Upper Bound"); defaultValue: 3.0 ; max: 3; decimals: 2}
      Slider
      {
        name: "grid_size"
        label: qsTr("Size of the Grid")
        value: 200
        vertical: false
        min: 2
        max: 10000
        decimals: 0
      }
  }

  Group
  {
    title: qsTr("Plots")
    CheckBox { name: "showCalibrationPlot"; label: qsTr("Calibration plot (adaptive C*)"); checked: true }
    CheckBox { name: "showDataSummaryPlot"; label: qsTr("Data summary (ln(eJAB01) vs pValue)"); checked: true }
  }
}
