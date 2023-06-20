####################################################################################################
#### Brad Pietruszka Line Suitability Index (LSI)
#### Author: Ben Gannon (benjamin.gannon@usda.gov)
#### Date Created: 03/08/2023
#### Last Modified: 06/20/2023
####################################################################################################
# Summary: This script applies Brad Pietruszka's translation between Potential Control Location
# Suitability (PCL) and Suppression Difficulty Index (SDI) to a localized line suitability index.
# It optionally extracts zonal statistics of PCL, SDI, and line suitability to user provided
# analysis polyline segements.
####################################################################################################
#-> Set working directory, file paths, and options
setwd('[USER SET PATH]/LSI_v6') # Set path to working directory
PCLin <- '[USER SET PATH]/Westwide_2023_PCL.tif' # Path to PCL raster
SDIin <- '[USER SET PATH]/SDI_2022_90th_percentile.tif' # Path to SDI raster
AAin <- './INPUT/analysis_area.shp' # Path to shapefile of analysis area
focrange <- FALSE # Switch for applying focal range option (either TRUE or FALSE) 
lowpass <- TRUE # Switch for applying low pass option (either TRUE or FALSE)
ALin <- './INPUT/POD_lines.shp' # Path to [OPTIONAL] analysis lines, comment out to skip
bdist <- 60 # Buffer distance for line analysis in meters, if selected
####################################################################################################

###########################################START MESSAGE############################################
cat('Brad Pietruszka Line Suitability Index (LSI)\n',sep='')
cat('Started at: ',as.character(Sys.time()),'\n\n',sep='')
cat('Messages, Errors, and Warnings (if they exist):\n')
####################################################################################################

############################################START SET UP############################################

#-> Load packages
pd <- .libPaths()[1]
packages <- c('terra','readxl','plyr')
for(package in packages){
	if(suppressMessages(!require(package,lib.loc=pd,character.only=T))){
		install.packages(package,lib=pd,repos='https://repo.miserver.it.umich.edu/cran/')
		suppressMessages(library(package,lib.loc=pd,character.only=T))
		require(paste(package))
	}
}

#-> load in PCL and SDI data
PCL <- rast(PCLin)
SDI <- rast(SDIin)

#-> Load in analysis area and project to match rasters
AA <- vect(AAin)
AA <- project(AA,PCL)

#-> Load in lookup table
lut <- data.frame(read_excel('./INPUT/lutable.xlsx'))

#############################################END SET UP#############################################

###########################################START ANALYSIS###########################################

#-> Clip and mask PCL and SDI rasters to analysis area
SDI <- mask(crop(SDI,AA),AA)
PCL <- mask(crop(PCL,AA),AA)

#-> Calculate SDI and PCL quantiles
PCL_brks <- quantile(values(PCL),seq(0,1,0.1),na.rm=T) # Get quantiles of PCL
SDI_brks <- quantile(values(SDI),seq(0,1,0.1),na.rm=T) # Get quantiles of SDI
qtab <- data.frame(Quantile=seq(0,1,0.1),SDI=SDI_brks,PCL=PCL_brks) # Put in table for saving
write.csv(qtab,'./OUTPUT/quantiles.csv',row.names=F) # Save breakpoints out for reference

#-> Convert lookup table to long form
# Use values 0 to 90 for PCL quantiles
# Use values 0 to 9 for SDI quantiles
lf_lut <- data.frame(Value=NA,Pcode=NA)[0,] # Long form classification table
for(i in 1:10){
	lf_lut <- rbind(lf_lut,data.frame(Value=seq(0,90,10)[i]+seq(0,9,1),Pcode=lut[,i+1]))
}

#-> Convert from SDI and PCL to Line Suitability Index (LSI)
PCLp <- classify(PCL,rcl=data.frame(Low=PCL_brks[1:10],High=PCL_brks[2:11],Value=seq(0,90,10)),
                 include.lowest=T) # PCL reclassed to values 0-90
SDIp <- classify(SDI,rcl=data.frame(Low=SDI_brks[1:10],High=SDI_brks[2:11],Value=seq(0,9,1)),
                 include.lowest=T) # SDI reclassed to values 0-9
CPI <- PCLp + SDIp # Add to create combined percentile index (PCL first digit, SDI second digit)
LSI <- classify(CPI,lf_lut) # Reclassed to Line Suitability Index (LSI)

#-> Colormap raster for png export function
# Inputs: raster, break points, list of colors for palette
# Returns raster with colormap
addCols <- function(inRast,breaks,cols){
	rClass <- classify(inRast,data.frame(Low=breaks[1:(length(breaks)-1)],
	                   High=breaks[2:length(breaks)],Value=breaks[1:(length(breaks)-1)]),
					   include.lowest=F) # Classify
	rgbvals <- col2rgb(colorRampPalette(cols)(length(breaks)-1)) # Colors
	coltab(rClass) <- data.frame(rgbvals[1,],rgbvals[2,],rgbvals[3,]) # Add colormap
	return(rClass)
}	

#-> Terra convert to KML function
# Could do this simpler using raster package, but this reduces dependencies
# Projects to WGS 84, save raster as PNG, create KML file
# Does not return anything, saves KML components to drive
saveKML <- function(inRast,outName){
	pRast <- project(inRast,crs('+proj=longlat +ellps=WGS84 +datum=WGS84'),method='near') # Project
	writeRaster(pRast,paste0(outName,'.png'),overwrite=T) # Export with rbg values
	pext <- ext(pRast) # Get extent in latitude and longitude
	kmlf <- file(paste0(outName,'.kml'),) # Create "KML" XML with spatial extent info
	fplist <- unlist(strsplit(outName,'/')); fname <- fplist[length(fplist)]
	sink(file=kmlf,append=T,type=c('output','message'),split=T)
	cat('<?xml version="1.0" encoding="UTF-8"?>\n',sep='')
	cat('<kml xmlns="http://www.opengis.net/kml/2.2">\n',sep='')
	cat('<GroundOverlay>\n',sep='')
	cat('<name>layer</name>\n',sep='')
	cat('<Icon><href>',fname,'.png</href><viewBoundScale>0.75</viewBoundScale></Icon>\n',sep='')
	cat('<LatLonBox>\n',sep='')
	cat('<north>',pext[4],'</north><south>',pext[3],'</south><east>',pext[2],'</east><west>',
	    pext[1],'</west>\n',sep='')
	cat('</LatLonBox>\n',sep='')
	cat('</GroundOverlay></kml>\n',sep='')
	sink()
	close(kmlf)
}

#-> Apply focal range option if selected, else select LSI as output raster
if(focrange){
	#-> Calculate focal range for 5 cell radius circular neighborhood
	cat('Applying focal range method\n')
	wm <- focalMat(LSI,5*res(LSI)[1],'circle') # Create weights matrix to define neighborhood
	wm[wm>0] <- 1; wm[wm==0] <- NA
	fmin <- focal(LSI,w=wm,fun='min',na.policy='omit') # Focal min
	fmax <- focal(LSI,w=wm,fun='max',na.policy='omit') # Focal max
	oRast <- fmax - fmin # Focal range
	#-> Apply low pass smoothing filter if selected
	# Using 3x3 rectangular neighborhood
	if(lowpass){
		oRast <- focal(oRast,w=3,fun='mean',na.policy='omit',na.rm=T) # Focal mean 3x3
	}
	#-> Save GeoTIFF
	writeRaster(oRast,'./OUTPUT/LSI_focrange.tif',overwrite=T)
	#-> Colormap raster
	colrast <- addCols(inRast=oRast,breaks=0:9,cols=c('red','orange','green','forestgreen','navy'))
	#-> Save KML
	saveKML(inRast=colrast,outName='./OUTPUT/LSI_focrange')
}else{
	#-> Use base LSI raster
	cat('Using base Line Suitability Index method\n')
	oRast <- LSI
	#-> Apply low pass smoothing filter if selected
	# Using 3x3 rectangular neighborhood
	if(lowpass){
		oRast <- focal(oRast,w=3,fun='mean',na.policy='omit',na.rm=T) # Focal mean 3x3
	}
	#-> Save GeoTIFF
	writeRaster(oRast,'./OUTPUT/LSI.tif',overwrite=T)
	#-> Colormap raster
	colrast <- addCols(inRast=oRast,breaks=0:9,cols=c('red','orange','green','forestgreen','navy'))
	#-> Save KML
	saveKML(inRast=colrast,outName='./OUTPUT/LSI')
}

#-> Quick map for confirmation
tiff('./OUTPUT/summary_map.tif',width=2100,height=1400,pointsize=24,compression='lzw',
     type='windows')
par(mfrow=c(2,3))
plot(PCL,breaks=c(0,10,25,50,75,100),main='Potential Control Location Suitability (PCL)',
     col=colorRampPalette(c('red','orange','green','forestgreen','navy'))(5),cex.main=1.2)
plot(SDI,breaks=c(0,10,20,40,70,100,318),main='Suppression Difficulty Index (SDI)',
     col=colorRampPalette(c('blue','cornsilk','red'))(6),cex.main=1.2)
titext <- ifelse(focrange,'Line Suitability Index (LSI) - Focal Range',
                 'Line Suitability Index (LSI)')
plot(oRast,breaks=seq(0,9,1),main=titext,
     col=colorRampPalette(c('red','orange','green','forestgreen','navy'))(9),cex.main=1.2)
par(mar=c(7.1,5.1,4.1,6.1))
hist(PCL,breaks=seq(0,100,5),
     main='Potential Control Location Suitability (PCL) Distribution',
     xlab='Potential Control Location Suitability (PCL)',axes=F)
axis(1,at=seq(0,100,10),labels=seq(0,100,10))
axis(2)
hist(SDI,breaks=seq(0,325,25),
     main='Suppression Difficulty Index (SDI) Distribution',
     xlab='Suppression Difficulty Index (SDI)',axes=F)
axis(1,at=seq(0,325,25),labels=c('0','','50','','100','','150','','200','','250','','300',''))
axis(2)
hist(oRast,breaks=seq(0,9,0.5),main=paste0(titext,' Distribution'),xlab=titext,axes=F)
axis(1,at=seq(0,9,1),labels=seq(0,9,1))
axis(2)
g <- dev.off()

###---> Optional line analysis
# Only triggered if alines object exists
if(exists('ALin')){
	
	cat('Line analysis in progress\n')

	#-> Read in analysis lines, clip to analysis area, and project to match rasters
	AL <- vect(ALin)
	AL <- project(AL,PCL)
	AL <- crop(AL,AA)
	
	#-> Add base attributes
	AL$LID <- seq(1,nrow(AL),1) # Add line ID field
	AL$Length_mi <- perim(AL)*0.000621371 # Get length of each line
	
	#-> Put rasters in list to mimic functionality of line analysis script
	# Order is PCL, SDI, LSI
	R.l <- list(PCL,SDI,oRast)
	rasters <- c('PCL','SDI',ifelse(focrange,'LSIfr','LSI'))
	
	#-> Convert lines to points
	# Note: the default behavior when rasterizizing polygons is attribution based on overlap with
	# the cell center. The results are reasonable when using a 30-m or larger buffer distance. 
	# Alternatively, you can use the "touches=T" option with smaller buffers to avoid gaps between
	# points generated for angled lines.
	alb <- buffer(AL,width=bdist) # Apply buffer
	ral <- rasterize(alb,R.l[[1]],field='LID') # Convert to raster
	alp <- as.points(ral,na.rm=T)
	alp$PID <- seq(1,nrow(alp),1)
	
	#-> Extract raster data to points
	for(j in 1:length(rasters)){
		alp$X <- extract(R.l[[j]],alp,factors=F)[,2] # Extract data
		names(alp)[ncol(alp)] <- rasters[j] # Rename field
	}

	#-> Attribute analysis lines with min, mean, and max of each metric
	for(j in 1:length(rasters)){
		alp$X <- data.frame(alp)[,paste(rasters[j])]
		xdf <- ddply(data.frame(alp),.(LID),summarize,
					 min = min(X,na.rm=T),
					 mean = mean(X,na.rm=T),
					 max = max(X,na.rm=T))
		AL <- merge(AL,xdf,by='LID',all.x=T)
		AL$min[is.na(AL$mean)] <- -1 # Recode NA so it is properly exported to shapefile
		AL$max[is.na(AL$mean)] <- -1
		AL$mean[is.na(AL$mean)] <- -1
		names(AL)[(ncol(AL)-2):ncol(AL)] <- paste(rasters[j],c('min','mean','max'),sep='_')
		alp$X <- NULL
	}	
	
	#-> Save analysis lines for mapping and analysis
	writeVector(AL,filename=paste0('./OUTPUT/line_analysis.shp'),overwrite=T)
	
}

############################################END ANALYSIS############################################

####################################################################################################
cat('\nFinished at: ',as.character(Sys.time()),'\n\n',sep='')
cat('Close command window to proceed!\n',sep='')
############################################END MESSAGE#############################################
