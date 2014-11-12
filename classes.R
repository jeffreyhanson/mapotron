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
	fields=list(featureLST="list", baseLST="list", featureId="ID", markerId="ID", activeId="character", activeBaseId="character", tool="numeric", emailOptions="list", args="list", startup="logical"),
	methods=list(
		initialize=function() {
			featureLST<<-list()
			baseLST<<-list()
			featureId<<-ID$new()
			markerId<<-ID$new()
			activeId<<- "-9999"
			activeBaseId<<-"-9999"
			tool<<-1
			startup<<-TRUE
			args<<-list()
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
			x=c('session$sendCustomMessage(\"set_cursor\",list(cursor=\"reset\", scope=\"all\"))')
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
					'session$sendCustomMessage(\"disable_button\",list(btn=\"annotationTxt\"))'
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
			featureLST[[as.character(Id)]]$annotation<<-sanitise(text)
		},
		download=function() {
			## prepare directories
			# create direcroties
			# generate user 
			userId=generateUserId(file.path("www","exports"))
			makeDirs(userId)
			dir.create(file.path("www","exports",userId,"data",userId), showWarnings=FALSE)
			zipPTH=file.path("www","exports",userId,"zip","spatialdata.zip")
			
			## export data
			saveSpatialData(featureLST,file.path("www","exports",userId,"data",userId),NULL)

			# generate zip file
			if (file.exists(zipPTH))
				file.remove(zipPTH)
			zip(zipPTH, list.files(file.path("www","exports",userId,"data",userId), full.names=TRUE), flags="-r9X -j -q")

			# return command to parse
			return(gsub(" ", "%20", paste0(shinyurl,file.path("exports",userId,"zip","spatialdata.zip")), fixed=TRUE))
		},
		
		export=function(firstname, lastname, emailaddress, emailtxt) {
			## test if email settings loaded
			if (length(emailOptions)==0) {
				stop("Email settings failed to load. You cannot send emails!")
			}
			## replace emailTxt with NA if NULL
			if (is.null(emailtxt))
				emailtxt=NA
			
			## prepare directories
			# generate a user id
			makeDirs(emailaddress)
			userId=generateUserId(file.path("www","exports",emailaddress,"data"))
			dir.create(file.path("www","exports",emailaddress,"data",userId), showWarnings=FALSE)			
			zipPTH=file.path("www","exports",emailaddress,"zip","spatialdata.zip")
			
			## export data
			saveSpatialData(featureLST,file.path("www","exports",emailaddress,"data",userId),c("firstname"=firstname,"lastname"=lastname, "message"=emailtxt))			
			
			# load spatial objects and combine them
			for (i in c("Point", "LineString", "Polygon")) {
				# get list of files
				currVEC=gsub(".shp", "", list.files(file.path("www","exports",emailaddress,"data"), paste0("^",i,".*.shp$"), full.names=TRUE, recursive=TRUE), fixed=TRUE)
				if (length(currVEC)>0) {
					currVEC=Map(readOGR, dirname(currVEC), basename(currVEC), verbose=FALSE)
					if (i %in% c("LineString","Polygon")) {					
						currVEC=lapply(seq_along(currVEC), function(x) {
							return(spChFIDs(currVEC[[x]], paste0(x,"_",row.names(currVEC[[x]]@data))))
						})
					}
					currShp=do.call(rbind, currVEC)
					writeOGR(
						currShp,
						file.path("www/exports",emailaddress,"temp"),
						i,
						overwrite=TRUE,
						driver="ESRI Shapefile"
					)
				}
			}
			
			# generate zip file
			if (file.exists(zipPTH))
				file.remove(zipPTH)
			zip(zipPTH, list.files(file.path("www/exports",emailaddress,"temp"), full.names=TRUE), flags="-r9X -j -q")
			
			## send email
			txt1=ifelse(nchar(emailtxt)==0,"",paste0("<p>They also left the following message: ",emailtxt,"</p>"))
			txt2=ifelse(emailaddress %in% emailWhiteList,"",paste0("<p><b>You have ",fileExpiry, "days to download this data before it is automatically deleted</b></p>"))
			send.mail(from = "mapotron@gmail.com", html=TRUE,
				to = paste0(firstname, " ", lastname, " <", emailaddress, ">"),
				subject = paste0(firstname," ",lastname," made you some spatial data!"),
				body = paste0("
<html>		
<body>
<p>Hi,</p>

<p>",capitalize(firstname)," ",capitalize(lastname)," generated some spatial data for you,</p>

",
txt1
,
"

<p>Download all the data people have made for you <a href=\"", gsub(" ", "%20", paste0(shinyurl,file.path("exports",emailaddress,"zip","spatialdata.zip")), fixed=TRUE),"\">here</a>.</p>

",
txt2
,"

<p>Cheers,</p>

<p><a href=\"",substr(shinyurl, 1, nchar(shinyurl)-1),"\">Mapotron</a></p>

<p>------------------</p>",
paste(paste0("<p>",capture.output(fortune()),"</p>"),collapse="\n"),
"

</body>
</html>
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
		},
		removeOldFiles=function() {
			# get date modified info for dirs
			dirVEC=setdiff(list.dirs(file.path("www","exports"),recursive=FALSE), emailWhiteList)
			if (length(dirVEC)>0) {
				# get modified date times for dirs
				dirVEC=dirVEC[which(difftime(Sys.time(),file.info(dirVEC)$mtime,units="days")>fileExpiry)]
				# delete dirs that haven't been modified in a while
				if (length(dirVEC)>0) {
					unlink(dirVEC, recursive=TRUE)
				}
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
			return(paste0("map$removeMarker('",featureId, "')"))
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
			return(paste0("map$removeGeoJSON('", featureId, "')"))
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
			return(paste0("map$removeGeoJSON('", featureId, "')"))
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

# geocoding class
GEOCODE=setRefClass("GEOCODE",
	fields=list(cache="list"),
	methods=list(
		initialize=function() {
			cache<<-list()
		},
		find=function(place) {
			place=tolower(place)
			pos=which(names(cache)==place)
			if (length(pos)==0) {
				ret=geocode.google(place)
				cache[[place]]<<-ret
				return(ret)
			} else {
				return(cache[[pos]])
			}
		}
	)
)
	
