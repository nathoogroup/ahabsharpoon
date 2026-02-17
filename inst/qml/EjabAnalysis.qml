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
  }
}
