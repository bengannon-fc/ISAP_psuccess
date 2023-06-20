# Line Suitability Index (LSI)
Line Suitability Index (LSI) is a relative metric of wildfire control line quality based on a quantile-normalized combination of Potential Control Location Suitability (PCL) and Suppression Difficulty Index (SDI). PCL is a statistical modeling framework for estimating control potential by relating observations of past fire control successes and failures to landscape characteristics (e.g., fuels, topography, and accessibility). PCL values range between 0 and 100 with higher numbers indicating greater potential for control. SDI is an expert-based index of suppression difficulty with potential fire behavior as a driving force in the numerator and factors that facilitate suppression as resisting forces in the denominator. SDI values range between 0 and 320 with higher values indicating greater suppression difficulty.

PCL and SDI rasters needed for the analysis can be found on the Risk Management Assistance SharePoint site.
https://firenet365.sharepoint.com/sites/RiskManagementAssistance/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FRiskManagementAssistance%2FShared%20Documents%2FRMA%20Dashboard&p=true&ga=1

<b>Inputs</b>
The inputs include SDI and PCL rasters, a user defined analysis area shapefile, and an optional user defined set of candidate control lines to evaluate. The SDI and PCL rasters must have the same spatial reference, resolution, and cell alignment. 

![image](https://github.com/bengannon-fc/Line_suitability_index/assets/81584637/f440202f-c7d0-4895-b4dd-2921b4dc4a92)

