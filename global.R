### default options
# options(shiny.error=traceback)

### load dependencies
library(rgdal)
library(leaflet)
library(maps)
library(fields)
library(RColorBrewer)
library(shinyBS)
library(mailR)
library(taRifx.geo)

### load classes
source("classes.R")

### define global variables
featurePals=c("Set1", "Set2", "Set3")
basePals=c("Pastel1", "Pastel2")
featureCol=unlist(Map(brewer.pal, brewer.pal.info[match(featurePals, rownames(brewer.pal.info)),1], featurePals))
baseCol=unlist(Map(brewer.pal, brewer.pal.info[match(basePals, rownames(brewer.pal.info)),1], basePals))
editCol="#FFFB0E"
selectCol="#00FFFF"
markerCol="#FF0000"
program_version="0.0.6"
load("data/baselayers.RDATA")
featureDefaultOptions=list(fillOpacity=0.5,opacity=1)
baseDefaultOptions=list(fillOpacity=0.2,opacity=0.3)
emailDF=read.table("other/emailaccount.csv", sep=",", header=TRUE, as.is=TRUE)
shinyurl="https://paleo13.shinyapps.io/mapotron/"
emailWhiteList=read.table("other/emailwhitelist.csv", sep=",", header=TRUE, as.is=TRUE)[,1,drop=TRUE]
emailBlockList=read.table("other/emailblocklist.csv", sep=",", header=TRUE, as.is=TRUE)[,1,drop=TRUE]
fileExpiry=7
google=GEOCODE$new()


### define functions
# misc functions
parseOpts=function(x) {
	return(unlist(x, recursive=FALSE))
}

featureColor=function(x) {
	return(featureCol[as.numeric(x) %% length(featureCol)])
}

baseColor=function(x) {
	return(baseCol[as.numeric(x) %% length(baseCol)])
}

# json functions
list2json=function(prefix,lst) {
	if (length(lst)==0) {
		return("")
	} else {
		return(paste0(prefix,"{",paste(unlist(Map(function(x,y) {
			if (is.numeric(y)) {
				return(paste0('"', x, '":', y))
			} else {
				return(paste0('"', x, '":"', y, '"'))
			}
		}, names(lst), unlist(lst, use.names=FALSE)), use.names=FALSE), collapse=","),"}"))
	}
}

# spatial functions
PointToSp=function(x) {
	# prepare data
	tempLST=list(id=numeric(0), coords=numeric(0), annotation=character(0))
	for (i in seq_along(x)) {
		if (nrow(x[[i]]$coords)>0) {
			tempLST$id = c(tempLST$id, rep(x[[i]]$featureId, nrow(x[[i]]$coords)))
			tempLST$annotation = c(tempLST$annotation, rep(x[[i]]$featureId, nrow(x[[i]]$coords)))
			tempLST$coords = rbind(tempLST$coords, x[[i]]$coords, deparse.level=0)
		}
	}
	class(tempLST$coords)="numeric"
	rownames(tempLST$coords)=seq_len(nrow(tempLST$coords))
	# convert to sp class
	return(SpatialPointsDataFrame(
		coords=tempLST$coords,
		data=data.frame(id=tempLST$id, annotation=tempLST$annotation),
		proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ")
	))
}

LineStringToSp=function(x) {
	tempLST=list()
	ids=c()
	annotations=c()
	for (i in seq_along(x)) {
		if (nrow(x[[i]]$coords)>0) {
			tempLST[[length(tempLST)+1]]=Lines(list(Line(x[[i]]$coords)), x[[i]]$featureId)
			ids[length(ids)+1]=x[[i]]$featureId
			annotations[length(annotations)+1]=x[[i]]$annotation
		}
	}
	return(SpatialLinesDataFrame(
		sl=SpatialLines(tempLST, proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ")),
		data=data.frame(
			id=ids,
			annotation=annotations,
			row.names=ids
		)
	))
}

PolygonToSp=function(x) {
	tempLST=list()
	ids=c()
	annotations=c()
	for (i in seq_along(x)) {
		if (nrow(x[[i]]$coords)>0) {
			tempLST[[length(tempLST)+1]]=Polygons(list(Polygon(x[[i]]$coords[c(seq_len(nrow(x[[i]]$coords)),1),])), x[[i]]$featureId)
			ids[length(ids)+1]=x[[i]]$featureId
			annotations[length(annotations)+1]=x[[i]]$annotation
		}
	}
	return(SpatialPolygonsDataFrame(
		Sr=SpatialPolygons(tempLST, proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ")),
		data=data.frame(
			id=ids,
			annotation=annotations,
			row.names=ids
		)
	))
}

