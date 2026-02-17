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
	icon        : "harpoon.png"
	preloadData: true
	requiresData: true

	GroupTitle
	{
		title:	qsTr("Detecting type I errors")
	}

	Analysis
	{
	  title: qsTr("eJAB Analysis")
	  menu: qsTr("eJAB Analysis")
	  func: "ejabAnalysis"
	  qml: "EjabAnalysis.qml"
	}
}
