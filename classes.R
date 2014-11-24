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
	fields=list(features="list", email="list", args="list"),
	methods=list(
		initialize=function() {
			features<<-list()
			email<<-list()
			args<<-list()
		},
		newFeature=function(id, data, mode, ...) {
			if (inherits(data, "SpatialPoints")) {
				features[[as.character(id)]]<<-POINT$new(id, data, mode, ...)
			} else if (inherits(data, "SpatialLines")) {
				features[[as.character(id)]]<<-LINESTRING$new(id, data, mode, ...)
			} else if (inherits(data, "SpatialPolygons")) {
				features[[as.character(id)]]<<-POLYGON$new(id, data, mode, ...)
			} else if (data$type=="Point") {
				features[[as.character(id)]]<<-POINT$new(id, data, mode, ...)
			} else if (data$type=="LineString") {
				features[[as.character(id)]]<<-LINESTRING$new(id, data, mode, ...)
			} else if (data$type=="Polygon") {
				features[[as.character(id)]]<<-POLYGON$new(id, data, mode, ...)
			}
		},
		updateFeature=function(id, json=NULL, sp=NULL, note=NULL, ...) {
			if (!is.null(json)) {
				features[[as.character(id)]]$update.json(json, ...)
			}
			if (!is.null(sp)) {
				features[[as.character(id)]]$update.sp(sp, ...)
			}			
			if (!is.null(note)) {
				features[[as.character(id)]]$.notes<<-note
			}
		},
		deleteFeature=function(id) {
			features<<-features[setdiff(names(features),id)]
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
			saveSpatialData(features[which(sapply(features, function(x){x$.mode=="rw"}))],file.path("www","exports",userId,"data",userId),NULL)

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
			saveSpatialData(features[which(sapply(features, function(x){x$.mode=="rw"}))],file.path("www","exports",emailaddress,"data",userId),c("firstname"=firstname,"lastname"=lastname, "message"=emailtxt))			
			
			# load spatial objects and combine them
			for (i in c("POINT", "LINESTRING", "POLYGON")) {
				# get list of files
				currVEC=gsub(".shp", "", list.files(file.path("www","exports",emailaddress,"data"), paste0("^",i,".*.shp$"), full.names=TRUE, recursive=TRUE), fixed=TRUE)
				if (length(currVEC)>0) {
					currVEC=Map(readOGR, dirname(currVEC), basename(currVEC), verbose=FALSE)
					if (i %in% c("LINESTRING","POLYGON")) {					
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
			diskGarbageCleaner()
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
	fields=list(.id="character", .mode="character", .name="character", .notes="character", .cols="character"),
)

POINT=setRefClass("POINT",
	contains="FEATURE",
	fields=list(.data="SpatialPoints", .radii="numeric"),
	methods=list(
		initialize=function(id, data, mode="rw", name=paste0("F",id), notes=NULL, cols=NULL) {
			.id<<-as.character(id)
			.mode<<-mode
			.name<<-name
			if (inherits(data, "SpatialPoints")) {
				update.sp(data)
			} else {
				update.json(data)
			}
			if (!is.null(notes)) {
				.notes<<-as.character(notes)
			} else {
				.notes<<-rep("", nrow(.data@coords))
			}
			if (is.null(cols)) {
				if (mode=="rw") {
					.cols<<-rep(defaultCol, nrow(.data@coords))
				} else if (mode=="r") {
					.cols<<-rep(defaultCol, nrow(.data@coords))
				}
			} else {
				.cols<<-cols
			}
		},
		update.json=function(jsonlst, ...) {
			.data<<-to.SpatialPoints.from.geojson(jsonlst)
		},
		update.sp=function(x) {
			.data<<-SpatialPoints(coords=x@coords,proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs "))	
			.radii<<-rep(as.numeric(NA), nrow(.data@coords))
		},
		to.json=function() {
			return(to.geojson.from.SpatialPoints(.data, .cols, .notes, defaultStyles[[.mode]]))
		},
		to.sp=function() {
			return(SpatialPointsDataFrame(coords=.data@coords, data=data.frame(note=.notes), proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ")))		
		}
	)
)

LINESTRING=setRefClass("LINESTRING",
	contains="FEATURE",
	fields=list(.data="SpatialLines"),
	methods=list(
		initialize=function(id, data, mode="rw", name=paste0("F",id), notes=NULL, cols=NULL, ...) {
			.id<<-as.character(id)
			.mode<<-mode
			.name<<-name
			if (inherits(data, "SpatialLines")) {
				update.sp(data)
			} else {
				update.json(data)
			}
			if (!is.null(notes)) {
				.notes<<-as.character(notes)
			} else {
				.notes<<-rep("", length(.data@lines))
			}
			if (is.null(cols)) {
				if (mode=="rw") {
					.cols<<-rep(defaultCol, length(.data@lines))
				} else if (mode=="r") {
					.cols<<-rep(defaultCol, length(.data@lines))
				}
			} else {
				.cols<<-cols
			}
		},
		update.json=function(jsonlst, ...) {
			.data<<-to.SpatialLines.from.geojson(jsonlst, .id)
		},
		update.sp=function(x) {
			.data<<-SpatialLines(x@lines, proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs "))
		},
		to.json=function() {
			return(to.geojson.from.SpatialLines(.data, .cols, .notes, defaultStyles[[.mode]]))
		},
		to.sp=function() {
			ids=paste0(.id,'_',seq_along(.notes))
			return(SpatialLinesDataFrame(.data, data=data.frame(note=.notes, row.names=ids)))
		},
		style=function() {
			retLST=list()
			for (i in seq_along(.data@lines)) {
				retLST[[i]]=defaultStyles[[.mode]]
				retLST[[i]]$color=.cols[[i]]
				retLST[[i]]$fillColor=.cols[[i]]
			}
			return(retLST)
		}		
	)	
)

POLYGON=setRefClass("POLYGON",
	contains="FEATURE",
	fields=list(.data="SpatialPolygons"),
	methods=list(
		initialize=function(id, data, mode="rw", name=paste0("F",id), notes=NULL, cols=NULL, ...) {
			.id<<-as.character(id)
			.mode<<-mode
			.name<<-name
			if (inherits(data, "SpatialPolygons")) {
				update.sp(data)
			} else {
				update.json(data)
			}
			if (!is.null(notes)) {
				.notes<<-as.character(notes)
			} else {
				.notes<<-rep("", length(.data@polygons))
			}
			if (is.null(cols)) {
				if (mode=="rw") {
					.cols<<-rep(defaultCol, length(.data@polygons))
				} else if (mode=="r") {
					.cols<<-rep(defaultCol, length(.data@polygons))
				}
			} else {
				.cols<<-cols
			}
		},
		update.json=function(jsonlst, ...) {
			.data<<-to.SpatialPolygons.from.geojson(jsonlst, .id)
		},
		update.sp=function(x) {
			.data<<-SpatialPolygons(x@polygons, proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs "))
		},
		to.json=function() {
			return(to.geojson.from.SpatialPolygons(.data, .cols, .notes, defaultStyles[[.mode]]))
		},
		to.sp=function() {
			ids=paste0(.id,'_',seq_along(.notes))
			return(SpatialPolygonsDataFrame(.data, data=data.frame(note=.notes, row.names=ids)))
		}
	)
)

