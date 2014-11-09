### default options
options(shiny.error=traceback)

### load dependencies
library(rgdal)
library(leaflet)
library(RColorBrewer)
library(shinyBS)
library(mailR)
library(taRifx.geo)
library(Hmisc)

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
program_version="1.0.2"
load("data/baselayers.RDATA")
featureDefaultOptions=list(fillOpacity=0.5,opacity=1)
baseDefaultOptions=list(fillOpacity=0.2,opacity=0.3)
emailDF=read.table("other/emailaccount.csv", sep=",", header=TRUE, as.is=TRUE)
shinyurl="https://paleo13.shinyapps.io/mapotron/"
emailWhiteList=read.table("other/emailwhitelist.csv", sep=",", header=TRUE, as.is=TRUE)[,1,drop=TRUE]
emailBlockList=read.table("other/emailblocklist.csv", sep=",", header=TRUE, as.is=TRUE)[,1,drop=TRUE]
fileExpiry=7
google=GEOCODE$new()
defaultZoom=6

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

sanitise=function(x) {
	x=deparse(x)
	chars=c("\\", "/", "'", '"', "<-", "=", "<<-")
	for (i in chars)
		x=gsub(i, "", x, fixed=TRUE)
	return(x)
}

geocode.google=function(placename) {
	# get data from google
	placeurl=paste0("http://maps.google.com/maps/api/geocode/", "json", "?address=", placename, "&sensor=", "false")
	doc=RCurl::getURL(placeurl)
	json=RJSONIO::fromJSON(doc, simplify=FALSE)
	# parse response
	if (json$status=="OK")  {
		return(
			list(
				lat=json$results[[1]]$geometry$location$lat,
				lng=json$results[[1]]$geometry$location$lng,
				name=json$results[[1]]$formatted_address,
				bbox=c(
					json$results[[1]]$geometry$bounds$northeast$lat,
					json$results[[1]]$geometry$bounds$northeast$lng,
					json$results[[1]]$geometry$bounds$southwest$lat,
					json$results[[1]]$geometry$bounds$southwest$lng
				),
				status=TRUE
			)
		)
	} else {
		return(list(lat=NA, lng=NA, name=NA, bbox=NA, status=FALSE))
	}
}

extractCoordinates=function(x) {
	splt=strsplit(gsub(" ", "", gsub("[a-zA-Z]","",x), fixed=TRUE), ",")
	return(as.numeric(c(splt[[1]][[1]], splt[[1]][[2]])))
}

generateUserId=function(x) {
	userId=paste0("user_",sample(1e+10,1))
	while(file.exists(file.path(x,userId))) {
		userId=paste0("user_",sample(1e+10,1))
	}
	return(userId)
}

# file management functions
makeDirs=function(dname) {
	dir.create(file.path("www/exports"), showWarnings=FALSE)
	dir.create(file.path("www/exports",dname), showWarnings=FALSE)
	dir.create(file.path("www/exports",dname,"temp"), showWarnings=FALSE)
	dir.create(file.path("www/exports",dname,"zip"), showWarnings=FALSE)
	dir.create(file.path("www/exports",dname,"data"), showWarnings=FALSE)
}

saveSpatialData=function(featureLST, expDir, attrVEC) {
	# generate nested list of objects
	tempLST=list(Point=list(), LineString=list(), Polygon=list())
	for (i in seq_along(featureLST)) {
		tempLST[[featureLST[[i]]$type]][[length(tempLST[[featureLST[[i]]$type]])+1]] = featureLST[[i]]
	}
	# save spatial objects
	for (i in seq_along(tempLST)) {
		if (length(tempLST[[i]])>0) {
			currSp=do.call(paste0(names(tempLST)[i],"ToSp"), list(tempLST[[i]]))
			for (j in seq_along(attrVEC))
				currSp@data[[names(attrVEC)[j]]]=attrVEC[[j]]
			writeOGR(
				currSp,
				expDir,
				names(tempLST)[i],
				overwrite=TRUE,
				driver="ESRI Shapefile"
			)
		}
	}
}

# make custom bs navbar
bsNavBar2=function (inputId, brandId, brand, ..., rightItems, fixed = FALSE, inverse = FALSE) 
{
    class <- "navbar"
    if (inverse) 
        class <- paste(class, "navbar-inverse")
    if (fixed) 
        class <- paste(class, "navbar-fixed-top")
    leftItems <- list(...)
    if (missing(rightItems))
        rightItems = list("")
    shinyBS:::sbsHead(
		tags$div(id = inputId, class = class, 
			tags$div(class = "navbar-inner", 
				tags$a(class = "brand", id = brandId, href = "#", brand), 
				tags$ul(class = "nav pull-left", leftItems), 
				tags$ul(class = "nav pull-right", rightItems)
			)
		)
	)
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

