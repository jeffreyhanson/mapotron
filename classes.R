### define classes
# toc class
TOC = setRefClass("TOC",
	fields=list(features="list", email="list", args="list"),
	methods=list(
		initialize=function() {
			features<<-list()
			email<<-list()
			args<<-list()
		},
		newFeature=function(id, json) {
			json=RJSONIO::fromJSON(json)
			switch(json$geometry$type,
				"Point"={newPoint(as.character(id), json)},
				"LineString"={newLineString(as.character(id), json)},
				"Polygon"={newPolygon(as.character(id), json)}
			)
		},
		updateFeature=function(id, json) {
			features[[as.character(id)]]$update(RJSONIO::fromJSON(json))
		},
		deleteFeature=function(id) {
			features<<-features[setdiff(names(features),id)]
		},
		newPoint=function(id, jsonlst) {
			features[[id]]<<-POINT$new(id, jsonlst)
		},
		newLineString=function(id, jsonlst) {
			features[[id]]<<-LINESTRING$new(id, jsonlst)
		},
		newPolygon=function(id, jsonlst) {
			features[[id]]<<-POLYGON$new(id, jsonlst)
		},
		newMultiPoint=function() {
			return()
		},
		newMultiLine=function() {
			return()		
		},
		newMultiPolygon=function() {
			return()
		},
		reset=function() {
			features<<-list()
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
			saveSpatialData(features,file.path("www","exports",userId,"data",userId),NULL)

			# generate zip file
			if (file.exists(zipPTH))
				file.remove(zipPTH)
			zip(zipPTH, list.files(file.path("www","exports",userId,"data",userId), full.names=TRUE), flags="-r9X -j -q")

			# return command to parse
			return(gsub(" ", "%20", paste0(shinyurl,file.path("exports",userId,"zip","spatialdata.zip")), fixed=TRUE))
		},
		
		export=function(firstname, lastname, emailaddress, emailtxt) {
			## test if email settings loaded
			if (length(email)==0) {
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
			saveSpatialData(features,file.path("www","exports",emailaddress,"data",userId),c("firstname"=firstname,"lastname"=lastname, "message"=emailtxt))			
			
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
			txt1=ifelse(nchar(emailtxt)==0,"",paste0("They also left the following message: ",emailtxt))
			txt2=ifelse(emailaddress %in% emailWhiteList,"",paste0("You have ",fileExpiry, " days to download this data before it is automatically deleted."))
			send.mail(from = "mapotron@gmail.com", html=FALSE,
				to = paste0(firstname, " ", lastname, " <", emailaddress, ">"),
				subject = paste0(firstname," ",lastname," made you some spatial data!"),
				body = paste0("
Hi,

",capitalize(firstname)," ",capitalize(lastname)," generated some spatial data for you,

",
txt1
,"

Download all the data people have made for you here:

", gsub(" ", "%20", paste0(shinyurl,file.path("exports",emailaddress,"zip","spatialdata.zip")), fixed=TRUE),"

",
txt2
,"

Cheers,

Mapotron (",substr(shinyurl, 1, nchar(shinyurl)-1),")

------------------",
parseFortune(fortune())

,"

")
,
				smtp = email,
				authenticate = TRUE,
				send = TRUE
			)
		},
		garbageCleaner=function() {
			memoryGarbageCleaner()
			diskGarbageCleaner()
		},
		memoryGarbageCleaner=function() {
			if (length(features)>0) {
				features<<-features[which(sapply(features, function(x) {
					return(nrow(x$.coords)>0)
				}))]
			}
		},
		diskGarbageCleaner=function() {
			# get date modified info for dirs
			dirs=setdiff(list.dirs(file.path("www","exports"),recursive=FALSE), emailWhiteList)
			if (length(dirs)>0) {
				# get modified date times for dirs
				dirs=dirs[which(difftime(Sys.time(),file.info(dirs)$mtime,units="days")>fileExpiry)]
				# delete dirs that haven't been modified in a while
				if (length(dirs)>0) {
					unlink(dirs, recursive=TRUE)
				}
			}
		}
	)
)

# feature class
FEATURE=setRefClass("FEATURE",
	fields=list(.id="character", .annotation="character", .coords="matrix"),
	methods=list(
		update=function(jsonlst) {
			.coords<<-matrix(.Internal(unlist(jsonlst$geometry$coordinates[[1]], FALSE, FALSE)),ncol=2,byrow=TRUE)	
		}
	)
)

POINT=setRefClass("POINT",
	contains="FEATURE",
	methods=list(
		initialize=function(id,jsonlst=NULL) {
			.id<<-id
			.coords<<-matrix(nrow=0, ncol=2)
			.annotation<<-""
			if (!is.null(jsonlst))
				update(jsonlst)
		},
		toGeoJSON=function() {
			return(paste0(
			   '{"type":"Feature",
				"properties":{},
				"geometry":{"type":"LineString","coordinates":  ',xyjson,' }
				}
			'))		
		},
		toSp=function() {
			return(SpatialPointsDataFrame(coords=.coords, data=data.frame(id=.id,annotation=.annotation, row.names=.id), proj4stirng=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ")))
		}
	)
)

LINESTRING=setRefClass("LINESTRING",
	contains="FEATURE",
	methods=list(
		initialize=function(id,jsonlst=NULL) {
			.id<<-id
			.coords<<-matrix(nrow=0, ncol=2)
			.annotation<<-""
			if (!is.null(jsonlst))
				update(jsonlst)
		},
		toGeoJSON=function() {
			return(paste0(
			   '{"type":"Feature",
				"properties":{},
				"geometry":{"type":"LineString","coordinates":  ',xyjson,' }
				}
			'))	
		},
		toSp=function() {
			return(
				SpatialLinesDataFrame(
					sl=SpatialLines(
						list(Lines(list(Line(.coords)), .id)),
						proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ")
					),
					data=data.frame(id=.id, annotation=.annotation, row.names=.id)
				)
			)
		}
	)
)

POLYGON=setRefClass("POLYGON",
	contains="FEATURE",
	methods=list(
		initialize=function(id,jsonlst=NULL) {
			.id<<-id
			.coords<<-matrix(nrow=0, ncol=2)
			.annotation<<-""
			if (!is.null(jsonlst))
				update(jsonlst)
		},
		toGeoJSON=function() {
			return(paste0(
			   '{"type":"Feature",
				"properties":{},
				"geometry":{"type":"Polygon","coordinates":  ',xyjson,' }
				}
			'))
		},
		toSp=function() {
			return(
				SpatialPolygonsDataFrame(
					Sr=SpatialPolygons(
						list(Polygons(list(Polygon(.coords)), .id)),
						proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ")
					),
					data=data.frame(id=.id, annotation=.annotation, row.names=.id)
				)
			)
		}
	)
)

