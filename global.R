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

### define global variables
featurePals=c("Set1", "Set2", "Set3")
basePals=c("Pastel1", "Pastel2")
featureCol=unlist(Map(brewer.pal, brewer.pal.info[match(featurePals, rownames(brewer.pal.info)),1], featurePals))
baseCol=unlist(Map(brewer.pal, brewer.pal.info[match(basePals, rownames(brewer.pal.info)),1], basePals))
editCol="#FFFB0E"
selectCol="#00FFFF"
markerCol="#FF0000"
program_version="0.0.5"
load("data/baselayers.RDATA")
featureDefaultOptions=list(fillOpacity=0.5,opacity=1)
baseDefaultOptions=list(fillOpacity=0.2,opacity=0.3)
emailDF=read.table("other/emailaccount.csv", sep=",", header=TRUE, as.is=TRUE)
shinyurl="https://paleo13.shinyapps.io/mapotron/"

### define classes
# id class
ID = setRefClass("ID", 
	fields=list(Id="numeric"),
	methods=list(
		initialize=function() {
			Id<<-0
		},
		new=function(n=1) {
			ret=as.character(seq(Id, Id+n-1))
			Id<<-Id+n
			return(ret)
		}
	)
)

# toc class
TOC = setRefClass("TOC",
	fields=list(featureLST="list", baseLST="list", featureId="ID", markerId="ID", activeId="character", activeBaseId="character", tool="numeric", emailOptions="list"),
	methods=list(
		initialize=function() {
			featureLST<<-list()
			baseLST<<-list()
			featureId<<-ID$new()
			markerId<<-ID$new()
			activeId<<- "-9999"
			activeBaseId<<-"-9999"
			tool<<-1
		},
		newPoint=function() {
			activeId<<-featureId$new()
			featureLST[[activeId]]<<-POINT$new(activeId, parseOpts(list(featureDefaultOptions, list(color=featureColor(activeId),fillColor=featureColor(activeId)))))
		},
		newLine=function() {
			activeId<<-featureId$new()
			featureLST[[activeId]]<<-LINE$new(activeId, parseOpts(list(featureDefaultOptions, list(color=featureColor(activeId),fillColor=featureColor(activeId)))))
		},
		newPolygon=function() {
			activeId<<-featureId$new()
			featureLST[[activeId]]<<-POLYGON$new(activeId, parseOpts(list(featureDefaultOptions, list(color=featureColor(activeId),fillColor=featureColor(activeId)))))
		},
		newBase=function(x) {
			if (inherits(x,"SpatialPolygonsDataFrame")) {
				newBaseId=featureId$new()
				baseLST[[newBaseId]]<<-list()
				for (i in seq_along(x@polygons)) {
					newSubId=featureId$new()
					for (j in seq_along(x@polygons[[i]]@Polygons)) {
						newSubSubId=paste0("base_",newBaseId,"_",featureId$new())
						baseLST[[newBaseId]][[newSubSubId]]<<-POLYGON$new(newSubSubId, parseOpts(list(baseDefaultOptions, list(color=baseColor(newSubId),fillcolor=baseColor(newSubId)))))
						baseLST[[newBaseId]][[newSubSubId]]$coords<<-x@polygons[[i]]@Polygons[[j]]@coords
						baseLST[[newBaseId]][[newSubSubId]]$annotation<<-as.character(x@data[[1]][i])
						baseLST[[newBaseId]][[newSubSubId]]$markerId<<-markerId$new(nrow(x@polygons[[i]]@Polygons[[j]]@coords))
					}
				}
			} else if (inherits(x, "SpatialLinesDataFrame")) {
				newBaseId=featureId$new()
				baseLST[[newBaseId]]<<-list()
				for (i in seq_along(x@lines)) {
					newSubId=featureId$new()
					for (j in seq_along(x@lines[[i]]@Lines)) {
						newSubId=paste0("base_",newBaseId,"_",featureId$new())
						baseLST[[newBaseId]][[newSubId]]<<-LINE$new(newSubId, parseOpts(list(baseDefaultOptions, list(color=baseColor(newSubId),fillcolor=baseColor(newSubId)))))
						baseLST[[newBaseId]][[newSubId]]$coords<<-x@lines[[i]]@Lines[[j]]@coords
						baseLST[[newBaseId]][[newSubId]]$annotation<<-as.character(x@data[[1]][i])
						baseLST[[newBaseId]][[newSubId]]$markerId<<-markerId$new(nrow(x@lines[[i]]@Lines[[j]]@coords))
					}
				}
			} else if (inherits(x, "SpatialPointsDataFrame")) {
				newBaseId=featureId$new()
				baseLST[[newBaseId]]<<-list()
				for (i in seq_len(nrow(x@coords))) {
					newSubId=paste0("base_",newBaseId,"_",featureId$new())
					baseLST[[newBaseId]][[newSubId]]<<-POINT$new(newSubSubId, parseOpts(list(baseDefaultOptions, list(color=featureColor(newSubId),fillcolor=featureColor(newSubId)))))
					baseLST[[newBaseId]][[newSubId]]$coords<<-x@coords[i,,drop=FALSE]
					baseLST[[newBaseId]][[newSubId]]$annotation<<-as.character(x@data[[1]][i])
					baseLST[[newBaseId]][[newSubId]]$markerId<<-markerId$new()
				}
			}
		},
		reset=function() {
			x=c()
			if (activeId!="-9999") {
				if (tool==1)
					x=deselectLayer()
				if (tool %in% 2:5)
					x=stopEditFeature()
				activeId<<- "-9999"
			}
			if (tool==1) {
				x=c(x,
					'session$sendInputMessage("annotationTxt", list(value=""))',
					'updateButton(session, "toolBtn6", disabled=TRUE)',
					"session$sendCustomMessage(type=\"jsCode\",list(code=\"$('#annotationTxt').prop('disabled',true)\"))"
				)
			}
			if (length(x)>0) {
				return(x)
			} else {
				return("")
			}
		},
		plotBase=function(Id) {
			return(sapply(baseLST[[as.character(Id)]], function(x) {
				return(x$plot())
			}))
		},
		removeBase=function(Id) {
			return(sapply(baseLST[[as.character(Id)]], function(x) {
				return(x$remove())
			}))
		},
		removeFeature=function(Id) {
			Id=as.character(Id)
			x=featureLST[[Id]]$remove()
			featureLST<<-featureLST[which(names(featureLST)!=Id)]
			return(x)
		},
		selectFeature=function(Id) {
			activeId<<-as.character(Id)
			return(c(
				featureLST[[activeId]]$plot(highlight=selectCol),
				featureLST[[activeId]]$addAnnotation()
			))
		},
		deselectFeature=function() {
			return(c(
				featureLST[[activeId]]$removeAnnotation(),
				featureLST[[activeId]]$plot())
			)
		},
		startEditFeature=function(Id) {
			activeId<<-as.character(Id)
			return(c(
				featureLST[[activeId]]$plot(highlight=editCol),
				featureLST[[activeId]]$addAllMarkers()
			))
		},
		stopEditFeature=function() {
			return(c(
				featureLST[[activeId]]$removeAllMarkers(),
				featureLST[[activeId]]$plot()
			))
		},
		plotFeature=function(Id, highlight=NULL) {
			return(featureLST[[as.character(Id)]]$plot(highlight))
		},
		plotAllFeatures=function() {
			currCol=NULL
			if (tool==1)
				currCol=selectCol
			if (tool %in% 2:5)
				currCol=editCol
			return(sapply(featureLST, function(x) {
				if (x$featureId==activeId) {
					return(x$plot(currCol))
				} else {
					return(x$plot(NULL))
				}
			}))
		},
		removeAllFeatures=function() {
			return(sapply(featureLST, function(x) {
				return(x$remove())
			}))
		},
		selectLayer=function(Id) {
			if (grepl("base_",Id) | grepl("sub_",Id)) {
				return(selectBase(Id))
			} else {
				return(selectFeature(Id))
			}
		},
		deselectLayer=function() {
			if (grepl("base_",activeId)) {
				return(deselectBase())
			} else {
				return(deselectFeature())
			}
		},
		selectBase=function(Id) {
			activeId<<-as.character(Id)
			return(c(
				baseLST[[strsplit(activeId, "_")[[1]][[2]]]][[activeId]]$plot(highlight=selectCol),
				baseLST[[strsplit(activeId, "_")[[1]][[2]]]][[activeId]]$addAnnotation()
			))
		},
		deselectBase=function() {
			return(c(
				baseLST[[strsplit(activeId, "_")[[1]][[2]]]][[activeId]]$removeAnnotation(),
				baseLST[[strsplit(activeId, "_")[[1]][[2]]]][[activeId]]$plot()
			))
		},
		
		addCoordinate=function(Id, coord) {
			newCoordId=markerId$new()
			featureLST[[as.character(Id)]]$addCoordinate(coord, newCoordId)
			featureLST[[as.character(Id)]]$addMarker(newCoordId)
		},
		removeCoordinate=function(Id, coordId) {
			featureLST[[as.character(Id)]]$removeCoordinate(coordId)
			featureLST[[as.character(Id)]]$removeMarker(coordId)
		},
		addAnnotation=function(Id, text) {
			featureLST[[as.character(Id)]]$annotation<<-text
		},
		export=function(firstname, lastname, emailaddress, emailtxt) {
			## prepare directories
			# create directory for researcher if not exist
			dir.create(file.path("www/exports",emailaddress), showWarnings=FALSE)
			# generate a user id
			userId=paste0("user_",sample(1e+10,1))
			while(file.exists(file.path("www/exports",emailaddress,"data",userId))) {
				userId=paste0("user_",sample(1e+10,1))
			}
			dir.create(file.path("www/exports",emailaddress,"data"), showWarnings=FALSE)
			dir.create(file.path("www/exports",emailaddress,"data",userId), showWarnings=FALSE)
			dir.create(file.path("www/exports",emailaddress,"user_zip"), showWarnings=FALSE)
			dir.create(file.path("www/exports",emailaddress,"all_zip"), showWarnings=FALSE)
			# generate file paths
			userZipPTH=file.path("www/exports",emailaddress,"user_zip",paste0(userId,"_data.zip"))
			emailZipPTH=file.path("www/exports",emailaddress,"all_zip","spatialdata.zip")
			
			## export data
			# generate nested list of objects
			tempLST=list(Point=list(), LineString=list(), Polygon=list())
			for (i in seq_along(featureLST)) {
				tempLST[[featureLST[[i]]$type]][[length(tempLST[[featureLST[[i]]$type]])+1]] = featureLST[[i]]
			}
			# save spatial objects
			for (i in seq_along(tempLST)) {
				if (length(tempLST[[i]])>0) {
					writeOGR(
						do.call(paste0(names(tempLST)[i],"ToSp"), list(tempLST[[i]])),
						file.path("www/exports",emailaddress,"data",userId),
						names(tempLST)[i],
						overwrite=TRUE,
						driver="ESRI Shapefile"
					)
				}
			}
			# prepare zip files
			zip(userZipPTH, list.files(file.path("www/exports",emailaddress,"data",userId), full.names=TRUE), flags="-r9X -j -q")
			if (file.exists(emailZipPTH))
				file.remove(emailZipPTH)
			zip(emailZipPTH, list.files(file.path("www/exports",emailaddress,"user_zip"), full.names=TRUE), flags="-r9X -j -q")
			
			## send email
			txt=ifelse(nchar(emailtxt)==0,"",paste0("They also left the following message: ",emailtxt))
			send.mail(from = "mapotron@gmail.com",
				to = emailaddress,
				subject = paste0(firstname," ",lastname," made you some spatial data!"),
				body = paste0("
Hi,

",firstname," ",lastname," generated some spatial data for you,

",
txt
,
"

Download this person's data at: ", shinyurl,userZipPTH, "

Batch download all the data people have sent you at: ", shinyurl,emailZipPTH,"

Cheers,

Mapotron Development Team (www.mapotron.com)

")
,
				smtp = emailOptions,
				authenticate = TRUE,
				send = TRUE
			)
		},
		garbageCleaner=function() {
			if (length(featureLST)>0) {
				featureLST<<-featureLST[which(sapply(featureLST, function(x) {
					return(nrow(x$coords)>0)
				}))]
			}
		}
	)
)

# feature class
FEATURE=setRefClass("FEATURE",
	fields=list(featureId="character", markerId="character", coords="matrix", annotation="character", type="character", options="list"),
	methods=list(
		addMarker=function(Id) {
			return(paste0("map$addMarker(", coords[which(markerId==Id),2] , ",", coords[which(markerId==Id),1], ",'marker_", Id, "')"))
		},
		addAllMarkers=function(Id) {
			return(paste0("map$addMarker(", coords[,2] , ",", coords[,1], ",'marker_", markerId, "')"))
		},
		removeMarker=function(Id) {
			return(paste0("map$removeMarker('marker_", Id, "')"))
		},
		removeAllMarkers=function() {
			return(paste0("map$removeMarker('marker_", markerId, "')"))
		},
		removeAnnotation=function() {
			return(paste0("map$removePopup('popup_", featureId, "')"))
		},
		addCoordinate=function(coord, Id) {
			coords<<-rbind(coords, coord)
			markerId<<-c(markerId, Id)
		},
		removeCoordinate=function(Id) {
			coords<<-coords[which(markerId!=Id),,drop=FALSE]
			markerId<<-markerId[which(markerId!=Id)]
		}
	)
)

POINT=setRefClass("POINT",
	contains="FEATURE",
	methods=list(
		initialize=function(Id, options) {
			featureId<<-Id
			coords<<-matrix(nrow=0, ncol=2)
			annotation<<-"NA"
			type<<-"Point"
			options<<-options
		},	
		remove=function() {
			return(paste0("map$removeMarker(",featureId, ")"))
		},
		plot=function(highlight=FALSE) {
			currOpts=options
			if (!is.null(highlight))
				currOpts$color=highlight
			currArgs=paste0("list(",paste(paste0('"',names(currOpts),'"', '="', unlist(currOpts, use.names=FALSE), '"'), collapse=","),")")
			return(paste0("map$addCircleMarker(", coords[,2], ", ", coords[,1],", 5, ", featureId, ", options=",currArgs,")"))
		},
		addAnnotation=function() {
			return(paste0("map$showPopup(",
				coords[,2],",",coords[,1],
				",content='",annotation,
				"',layerId='popup_",featureId,"')"))
		}		
	)
)

LINE=setRefClass("LINE",
	contains="FEATURE",
	methods=list(
		initialize=function(Id, options) {
			featureId<<-Id
			coords<<-matrix(nrow=0, ncol=2)
			annotation<<-"NA"
			type<<-"LineString"
			options<<-options
		},		
		remove=function() {
			return(paste0("map$removeGeoJSON(", featureId, ")"))
		},
		plot=function(highlight=NULL) {
			xyjson = RJSONIO::toJSON(coords)
			currOpts=options
			if (!is.null(highlight))
				currOpts$color=highlight
			jsonX = RJSONIO::fromJSON(paste0(
			   '{"type":"Feature",
				"properties":{"region_id":1, "region_name":"My Region"},
				"geometry":{"type":"LineString","coordinates":  ',xyjson,' },
				',list2json('"style":',currOpts),'
				}
			'
			))
			return(paste0("map$addGeoJSON(",paste(deparse(jsonX), collapse=""),", '", featureId, "')"))
		},
		addAnnotation=function() {
			pos=ceiling(nrow(coords)/2)
			return(paste0("map$showPopup(",
				coords[pos,2],",",coords[pos,1],
				",content='",annotation,
				"',layerId='popup_",featureId,"')"))
		}
	)
)

POLYGON=setRefClass("POLYGON",
	contains="FEATURE",
	methods=list(
		initialize=function(Id, options) {
			featureId<<-Id
			coords<<-matrix(nrow=0, ncol=2)
			annotation<<-"NA"
			type<<-"Polygon"
			options<<-options
		},
		remove=function() {
			return(paste0("map$removeGeoJSON(", featureId, ")"))
		},
		plot=function(highlight=NULL) {
			xyjson = RJSONIO::toJSON(matrix(as.character(c(coords[,1], coords[,2], markerId)), ncol=3))
			currOpts=options
			if (!is.null(highlight))
				currOpts$color=highlight
			jsonX = RJSONIO::fromJSON(paste0(
			   '{"type":"Feature",
				 "properties":{"region_id":1, "region_name":"My Region"},
				 "geometry":{"type":"Polygon","coordinates": [ ',xyjson,' ]},
				 ',list2json('"style":',currOpts),'
				}
				'
			))
			return(paste0("map$addGeoJSON(",paste(deparse(jsonX), collapse=""),", '", featureId, "')"))
		},
		addAnnotation=function() {
			return(paste0("map$showPopup(",
				mean(coords[,2],na.rm=TRUE),",",mean(coords[,1],an.rm=TRUE),
				",content='",annotation,
				"',layerId='popup_",featureId,"')"))
		}		
	)
)

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
			tempLST[[length(tempLST)+1]]=Polygons(list(Polygon(rbind(x[[i]]$coords[1,], deparse.level=0))), x[[i]]$featureId)
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

