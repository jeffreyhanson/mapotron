### define functions
bindEvent <- function(eventExpr, callback, env=parent.frame(), quoted=FALSE) {
  eventFunc <- exprToFunction(eventExpr, env, quoted)
  initialized <- FALSE
  invisible(observe({
    eventVal <- eventFunc()
    if (!initialized)
      initialized <<- TRUE
    else
      isolate(callback())
  }))
}

### add resources
addResourcePath('www', 'www')

### shiny server function
shinyServer(function(input, output, session) {
	## initialization
	# initialize widgets
	map=createLeafletMap(session, 'map')
	toc=TOC$new()
	id=ID$new()
	# load email data
	if (!inherits(email.params.LST, "try-error")) {
		toc$email=list(api.key=email.params.LST$api.key, api.url=email.params.LST$api.url, api.address=email.params.LST$api.address)
	} else {
		warning("File containing email details failed to load, check \"emailDF\" in global.R")
	}
	# get program arguments and execute startup parameters
	toc$args=parseQueryString(isolate(session$clientData$url_search))
	session$onFlushed(once=TRUE, function() {
		# centre map on user-specified location
		if (!is.null(toc$args$lat) & !is.null(toc$args$lng) & !is.null(toc$args$zoom)) {
			if (toc$args$lat<90 & toc$args$lat>-90 & toc$args$lng<180 & toc$args$lng>-180) {
				map$setView(as.numeric(toc$args$lat), as.numeric(toc$args$lng), as.numeric(toc$args$zoom), FALSE)
			}
		}
		# load basemap data
		if (!is.null(toc$args$emailaddress)) {
			if (file.exists(file.path(data.params.LST[['data.directory']],dname,"basemap"))) {
				files <- dir(file.path(data.params.LST[['data.directory']],dname,"basemap"), '^.*\\.rds', full.names=TRUE)
				for (f in files) {
					d <- readRDS(d)
					if (!is.list(d)) {
						d <- structure(d, names='Data')
					}
					for (di in seq_along(d)) {
						if (is.Spatial(d[[di]])) {
							if (nrow(baselayers[[i]]@data)<30) {
								currCols=rCols[seq_len(nrow(d[[di]]@data))]
							} else {
								currCols=rep(rCols[di],nrow(d[[di]]@data))
							}
								toc$newFeature(paste0('r_',id$new()), d[[di]], 'r', names(d)[di], d[[di]]@data[[1]], currCols)
							}
						}
				}
			}
		}
		# set args to automatically send data on close
		if (!is.null(toc$args$firstname) & !is.null(toc$args$lastname) & !is.null(toc$args$emailaddress)) {
			# set auto_send variable
			session$sendCustomMessage("update_var",list(var="auto_send", val="true"))
			# set style as disable
			session$sendCustomMessage("disable_button",list(btn="emailBtn"))
			# change tool tip
			removeTooltip(session,"emailBtn")
			addTooltip(session,"emailBtn", "Data will automatically be emailed.", placement = "bottom", trigger = "hover")
			# set app to automatically send email on close if details are supplied
			session$onSessionEnded(function() {
				toc$garbageCleaner()
				if (length(toc$features)!=0)
					try(toc$export(toc$args$firstname, toc$args$lastname, toc$args$emailaddress, toc$args$message))
			})
		}
	})
	# set clean
	session$sendCustomMessage("update_var",list(var="is_dirty", val="false"))
	
	## new feature
	observe({
		if (is.null(input$map_create))
			return()
		isolate({
			if (is.null(input$map_create$radii)) {
				toc$newFeature(input$map_create$id, RJSONIO::fromJSON(input$map_create$geojson)$geometry, "rw")
			} else {
				toc$newFeature(input$map_create$id, to.SpatialPolygons.from.circle(RJSONIO::fromJSON(input$map_create$geojson)$geometry, id=input$map_create$id, radii=input$map_create$radii), "rw")
			}
			
			session$sendCustomMessage("update_var",list(var="is_dirty", val="true"))
		})
	})
	
	## update existing features
	observe({
		if (is.null(input$map_edit))
			return()
		isolate({
			for (i in seq_along(input$map_edit$list)) {
				if (is.null(input$map_edit$list[[i]]$radii)) {
					toc$updateFeature(input$map_edit$list[[i]]$id, json=RJSONIO::fromJSON(input$map_edit$list[[i]]$geojson)$geometry)
				} else {
					toc$updateFeature(input$map_edit$list[[i]]$id, sp=to.SpatialPolygons.from.circle(RJSONIO::fromJSON(input$map_edit$list[[i]]$geojson)$geometry, id=input$map_edit$list[[i]]$id, radii=input$map_edit$list[[i]]$radii))
				}
			}
			session$sendCustomMessage("update_var",list(var="is_dirty", val="true"))
		})
	})
	observe({
		if (is.null(input$map_note))
			return()
		isolate({
			toc$updateFeature(as.character(input$map_note$id),note=sanitise(input$map_note$text))
			map$removePopup("map_add_note")
			session$sendCustomMessage("update_var",list(var="is_dirty", val="true"))
		})
	})

	## delete existing feature
	observe({
		if (is.null(input$map_delete))
			return()
		isolate({
			for (i in seq_along(input$map_delete$id)) {
				toc$deleteFeature(input$map_delete$id[[i]])
			}
			session$sendCustomMessage("update_var",list(var="is_dirty", val="true"))
		})
	})
	
	## download data
	observe({
		if (is.null(input$downloadBtn))
			return()
		if (input$downloadBtn==0)
			return()
		isolate({
			toc$garbageCleaner()
			session$sendCustomMessage("download_file",list(message=toc$download()))
			session$sendCustomMessage("update_var",list(var="is_dirty", val="false"))
		})
	})
	
	## email button observer
	observe({
		if (is.null(input$emailBtn))
			return()
		if (input$emailBtn==0)
			return()
		isolate({
			# if custom email supplied
			session$sendCustomMessage("set_cursor",list(cursor="wait", scope="all"))
			if (!is.null(toc$args$firstname) & !is.null(toc$args$lastname) & !is.null(toc$args$emailaddress)) {
				# init
				session$sendCustomMessage("disable_button",list(btn="emailBtn"))
				toc$garbageCleaner()
				# main
				if ((!toc$args$emailaddress %in% emailBlockList) & length(toc$features)>0) {
					try(toc$export(toc$args$firstname, toc$args$lastname, toc$args$emailaddress, toc$args$message))
				}
				# post
				session$sendCustomMessage("enable_button",list(btn="emailBtn"))		 		 
			} else {
				toggleModal(session, "emailMdl")
			}
			# update buttons
			session$sendCustomMessage("set_cursor",list(cursor="reset", scope="all"))
			# set clean
			session$sendCustomMessage("update_var",list(var="is_dirty", val="false"))
		})
	})	
	
	## send email
	observe({
		if (input$sendEmailBtn==0)
			return()
		isolate({
			# init
			session$sendCustomMessage("disable_button",list(btn="sendEmailBtn"))
			session$sendCustomMessage("set_cursor",list(cursor="wait", scope="all"))
			alert=NULL
			toc$garbageCleaner()
			# main
			x=list("First Name"=input$firstName, "Last Name"=input$lastName, "Email Address"=input$emailAddress)
			if (length(toc$features)==0) {
				alert=list(text="No spatial data!",type="danger")
			} else {
				if (input$emailAddress %in% emailBlockList) {
					alert=list(text="This email address has been blocked!",type="danger")
				} else if (all(sapply(x, nchar)>0)) {
					# save shapefiles
					x=try(toc$export(x[[1]], x[[2]], x[[3]], input$emailtxt))
					if (inherits(x,"try-error")) {
						alert=list(text=paste("Error processing data!", x[1]),type="danger")
					}
				} else {
					y=which(sapply(x, nchar)==0)
					if (length(y)==1) {
						alert=list(text=paste0(names(x)[y], " field is incomplete!"),type="danger")
					} else {
						alert=list(text=paste0(paste(names(x)[y], collapse=" and "), " fields are incomplete!"),type="danger")
					}
				}
			}
			# create alert
			if (!is.null(alert)) {
				createAlert(session, inputId = "alertAchr",
					message = alert$text,
					type = alert$type,
					dismiss = TRUE,
					block = FALSE,
					append = FALSE
				)
			}
			# update button
			session$sendCustomMessage("enable_button",list(btn="sendEmailBtn"))
			session$sendCustomMessage("set_cursor",list(cursor="reset", scope="all"))
			# set clean
			session$sendCustomMessage("update_var",list(var="is_dirty", val="false"))
		})
	})
	
	# load data
	observe({
		if (is.null(input$map_load_data))
			return()
		isolate({
			# send rfeatures to leaflet
			for (i in seq_along(toc$features)) {
				if (toc$features[[i]]$.mode=="r") {
					map$addFeature(toc$features[[i]]$.id, toc$features[[i]]$to.json(), 'r', toc$features[[i]]$.name)
				}
			}
		})
	})
})




