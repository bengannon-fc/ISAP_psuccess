# Line Suitability Index (LSI)
Line Suitability Index (LSI) is a relative metric of wildfire control line quality based on a quantile-normalized combination of Potential Control Location Suitability (PCL) and Suppression Difficulty Index (SDI). PCL is a statistical modeling framework for estimating control potential by relating observations of past fire control successes and failures to landscape characteristics (e.g., fuels, topography, and accessibility). PCL values range between 0 and 100 with higher numbers indicating greater potential for control. SDI is an expert-based index of suppression difficulty with potential fire behavior as a driving force in the numerator and factors that facilitate suppression as resisting forces in the denominator. SDI values range between 0 and 320 with higher values indicating greater suppression difficulty.

PCL and SDI rasters needed for the analysis can be found on the Risk Management Assistance SharePoint site.
https://firenet365.sharepoint.com/sites/RiskManagementAssistance/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FRiskManagementAssistance%2FShared%20Documents%2FRMA%20Dashboard&p=true&ga=1

<b>Inputs</b><br>
The inputs include PCL and SDI rasters, an LSI classification matrix, a user defined analysis area shapefile, and an optional user defined shapefile of candidate control lines to evaluate. The SDI and PCL rasters must have the same spatial reference, resolution, and cell alignment. User defined shapefiles can be in any spatial reference as long as it is defined. 

<b>Analysis</b><br>
The PCL and SDI rasters are first clipped to the user provided analysis area. Local PCL and SDI percentiles are then calculated. The PCL and SDI percentiles are then classified into LSI per the following table. The default is to apply a 3x3 low pass filter to the resulting LSI values to acknowledge input data limitiations at fine scales.

![image](https://github.com/bengannon-fc/Line_suitability_index/assets/81584637/f440202f-c7d0-4895-b4dd-2921b4dc4a92)

If candidate control lines are provided, the underlying SDI, PCL, and LSI values will be summarized to the lines using zonal statistics. The user can modify the buffer distance used to define the summary zone around each line.

<b>Outputs</b><br>
- LSI raster (for GIS)
- LSI png and kml (for Google Earth)
- PCL and SDI quantiles table
- Summary maps and histograms
- Candidate control line shapefile (if requested)
  
![image](https://github.com/bengannon-fc/Line_suitability_index/assets/81584637/982f9ba0-c63e-486f-9098-2354bc8da1ec)



