import QtQuick
import JASP.Module

Description
{
	name		: "AhabsHarpoon"
	title		: qsTr("Ahab's Harpoon")
	description	: qsTr("Detecting type I errors using Bayes-frequentist contradictions")
	version		: "0.1"
	author		: "Farouk Nathoo, Puneet Velidi, Zhengxiao Wei, Evan Strasdin"
	maintainer	: "Evan Strasdin <evn.strsdn@pm.me>"
	website		: "https://github.com/nathoogroup/ahabsharpoon"
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
