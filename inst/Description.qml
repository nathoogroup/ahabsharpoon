import QtQuick
import JASP.Module

Description
{
	name		: "AhabsHarpoon"
	title		: qsTr("Ahab's Harpoon")
	description	: qsTr("Detecting type I errors using Bayes-frequentist contradictions")
	version		: "0.1"
	author		: "JASP Team"
	maintainer	: "JASP Team <info@jasp-stats.org>"
	website		: "https://jasp-stats.org"
	license		: "GPL (>= 2)"
	icon        : "harpoon.png" // Located in /inst/icons/
	preloadData: true
	requiresData: true

	GroupTitle
	{
		title:	qsTr("Basic interactivity, Test")
	}

	Analysis
	{
		title: qsTr("Using the interface") // Title for window
		menu: qsTr("Using the interface")  // Title for ribbon
		func: "interfaceExample"           // Function to be called
		qml: "Interface.qml"               // Design input window
		requiresData: false                // Allow to run even without data
	}

	Analysis
	{
	  title: qsTr("Loading data")
	  menu: qsTr("Loading data")
	  func: "processTable"
	  qml: "LoadingData.qml"
	}

	GroupTitle
	{
		title:	qsTr("Detecting type I errors")
	}

	Analysis
	{
	  title: qsTr("Analyze")        // Title for window
	  menu: qsTr("Analyze")         // Title for ribbon
	  func: "addOne"                // Function to be called
    qml: "AddOne.qml"            // Design input window
	  requiresData: false           // Allow to run even without data
	}

}
