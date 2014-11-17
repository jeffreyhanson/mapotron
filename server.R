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

### shiny server function
shinyServer(function(input, output, session) {
	## initialization
	# prepare toc
	map=createLeafletMap(session, 'map')
	toc=TOC$new()
	id=ID$new()
	for (i in seq_along(baselayers)) {
		toc$newFeature(paste0('r_',id$new()), baselayers[[i]], 'r', names(baselayers)[i], baselayers[[i]]@data[[1]], rCols[seq_len(nrow(baselayers[[1]]@data))])
	}
	if (!inherits(emailDF, "try-error")) {
		toc$email=list(host.name=emailDF$host.name, port=emailDF$port, user.name=emailDF$user.name, passwd=emailDF$password, ssl=TRUE)
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
		# set args to automatically send data on close
		if (!is.null(toc$args$firstname) & !is.null(toc$args$lastname) & !is.null(toc$args$emailaddress)) {
			# set auto_send variable
			session$sendCustomMessage("update_var",list(var="auto_send", val="true"))
			# set app to automatically send email on close if details are supplied
			session$onSessionEnded(function() {			
				toc$garbageCleaner()
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
		isolate({?asve
			toc$newFeature(input$map_create$id, RJSONIO::fromJSON(input$map_create$geojson)$geometry, "rw")
			session$sendCustomMessage("update_var",list(var="is_dirty", val="true"))
		})
	})
	
	## update existing features
	observe({
		if (is.null(input$map_edit))
			return()
		isolate({
			x=input$map_edit
			save(x,file="debug/test.RDATA")
			for (i in seq_along(input$map_edit$list)) {
				toc$updateFeature(input$map_edit$list[[i]]$id, json=RJSONIO::fromJSON(input$map_edit$list[[i]]$geojson)$geometry)
			}
			session$sendCustomMessage("update_var",list(var="is_dirty", val="true"))
		})
	})
	observe({
		if (is.null(input$map_note))
			return()
		isolate({
			toc$updateFeature(sanitise(as.character(input$map_note$id),note=input$map_note$text))
			map$removePopup("map_add_note")
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




