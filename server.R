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
	### initialization
	# prepare toc
	map=createLeafletMap(session, 'map')
	toc=TOC$new()
	for (i in seq_along(baselayers)) {
		toc$newBase(baselayers[[i]])
	}
	toc$emailOptions=list(host.name=emailDF$host.name, port=emailDF$port, user.name=emailDF$user.name, passwd=emailDF$password, ssl=TRUE)
	session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('disabled',true)"))	

	# get program arguments
	observe({
		if (!toc$startup)
			return()
		isolate({
			toc$args<<-parseQueryString(session$clientData$url_search)
			if (!is.null(toc$args$lat) & !is.null(toc$args$lng) & !is.null(toc$args$zoom)) {
				if (toc$args$lat<90 & toc$args$lat>-90 & toc$args$lng<180 & toc$args$lng>-180) {
					map$setView(toc$args$lat, toc$args$lng, toc$args$zoom)
				}
			}
			toc$startup<<-FALSE
		})
	})
	
	# baselayer select widget
	vec=c("-9999", names(toc$baseLST))
	names(vec)=c("None",names(baselayers))
	updateDropDown(session, "baseSel", label="Base Layer", choices=vec)
		
	### observers
	## baselayer observer
	observe({
		Id=input$baseSel
		if (is.null(Id))
			return()
		isolate({		
			# remove basemap
			if (toc$activeBaseId!="-9999") {
				eval(parse(text=toc$removeBase(toc$activeBaseId)))
			}
			# add new basemap
			toc$activeBaseId<<-Id
			if (Id!="-9999") {
				eval(parse(text=toc$plotBase(Id)))
			}
			# replot features
			toc$removeAllFeatures()
			toc$plotAllFeatures()
		})
	})
	## map click button observer
	observe({
		if (input$toolBtn1==0)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset()))
			# reset previous tool button
			suppressWarnings(updateButton(session, paste0("toolBtn",toc$tool), style="inverse"))
			# highlight current tool button
			updateButton(session, "toolBtn1", style="primary")
			# set tool
			toc$tool<<-1
			
		})
	})
	# add point button observer
	observe({
		if (input$toolBtn2==0)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset()))
			# reset previous tool button
			suppressWarnings(updateButton(session, paste0("toolBtn",toc$tool), style="inverse"))
			# highlight current tool button
			updateButton(session, "toolBtn2", style = "primary")
			# set tool
			toc$tool<<-2
		})
	})
	# add line button observer
	observe({
		if (input$toolBtn3==0)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset())) 
			# reset previous tool button
			suppressWarnings(updateButton(session, paste0("toolBtn",toc$tool), style="inverse"))
			# highlight current tool button
			updateButton(session, "toolBtn3", style = "primary")
			# set tool
			toc$tool<<-3
			toc$newLine()
		})
	})
	# add polygon button observer
	observe({
		if (input$toolBtn4==0)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset()))
			# reset previous tool button
			suppressWarnings(updateButton(session, paste0("toolBtn",toc$tool), style="inverse"))
			# highlight current tool button
			updateButton(session, "toolBtn4", style = "primary")
			# set tool
			toc$tool<<-4
			toc$newPolygon()
		})
	})
	# edit button observer
	observe({
		if (input$toolBtn5==0)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset()))
			# reset previous tool button
			suppressWarnings(updateButton(session, paste0("toolBtn",toc$tool), style="inverse"))
			# highlight current tool button
			updateButton(session, "toolBtn5", style = "primary")
			# set status
			toc$tool<<-5
		})
	})
	# annotate text input observer 
	observe({
		if (nchar(input$annotationTxt)>0 & toc$tool==1) {
			isolate({
				# update annotation
				toc$addAnnotation(toc$activeId,input$annotationTxt)			
				# update popup
				eval(parse(text=toc$featureLST[[toc$activeId]]$addAnnotation()))
			})
		}
	})
	# geocode text input observer
	observe({	
		if (input$geocodeTxt=="")
			return()
		isolate({
			coords=try(extractCoordinates(sanitise(input$geocodeTxt)),silent=TRUE)
			if (!inherits(coords,"try-error")) {
				if (coords[1]<90 & coords[1]>-90 & coords[2]<180 & coords[2]>-180) {
					map$setView(coords[1], coords[2], defaultZoom)
					map$showPopup(coords[1], coords[2], input$geocodeTxt, "geocode_marker")
				} else {
					return()
				}
			} else {
				ret=google$find(sanitise(input$geocodeTxt))
				if (ret$status) {
					map$fitBounds(ret$bbox[1], ret$bbox[4], ret$bbox[3], ret$bbox[2])
					map$showPopup(ret$lat, ret$lng, ret$name, "geocode_marker")
				}
			}
		})
		
		
	})
	# remove button observer
	observe({
		if (input$toolBtn7==0)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset()))
			# reset previous tool button
			suppressWarnings(updateButton(session, paste0("toolBtn",toc$tool), style="inverse"))
			# highlight current tool button
			updateButton(session, "toolBtn7", style = "primary")
			# set status
			toc$tool<<-7
		})
	})
	
	## select layer
	# marker click
	observe({
		event = input$map_marker_click
		if (is.null(event) | toc$tool!=1)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset()))
			# select layer
			eval(parse(text=toc$selectLayer(event$id)))
			session$sendInputMessage("annotationTxt", list(value=toc$featureLST[[toc$activeId]]$annotation))
			# update widgets
			if (!grepl("base_",event$id)) {
				updateButton(session, "toolBtn6", disabled=FALSE)
				session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('disabled',false)"))
				session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('readonly',false)"))
			} else {
				updateButton(session, "toolBtn6", disabled=TRUE)
				session$sendInputMessage("annotationTxt", list(value=toc$baseLST[[strsplit(toc$activeId, "_")[[1]][[2]]]][[toc$activeId]]$annotation))
				session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('disabled',true)"))	
				session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('readonly',true)"))
			}
		})
	})	
	# geojson click
	observe({
		event = input$map_geojson_click
		if (is.null(event) | toc$tool!=1)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset()))
			if (!grepl("base_",event$id)) {
				## if feature layer			
				# add popup
				eval(parse(text=toc$selectFeature(event$id)))
				session$sendInputMessage("annotationTxt", list(value=toc$featureLST[[toc$activeId]]$annotation))
				# enable annotation widgets
				updateButton(session, "toolBtn6", disabled=FALSE)
				session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('disabled',false)"))
				session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('readonly',false)"))				
			} else {
				## if base layer
				# add popup
				eval(parse(text=toc$selectBase(event$id)))
				session$sendInputMessage("annotationTxt", list(value=toc$baseLST[[strsplit(toc$activeId, "_")[[1]][[2]]]][[toc$activeId]]$annotation))
				session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('disabled',true)"))	
				session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('readonly',true)"))
			}
		})
	})
	## deselect layer
	observe({
		event=input$map_click
		if (is.null(event) | toc$tool!=1)
			return()
		isolate({
			# reset
			eval(parse(text=toc$reset()))
		})
	})
	
	## edit layer observer
	# add a coordinate on map click
	observe({
		event=input$map_click
		if  (!(!is.null(event) & ((toc$tool %in% c(2:5) &  toc$activeId!="-9999") | (toc$tool==2))))
			return()
		isolate({
			#  create new feature if point
			if (toc$tool==2) {
				eval(parse(text=toc$reset()))
				toc$newPoint()
			}
			# add coordinate and marker
			eval(parse(text=toc$addCoordinate(toc$activeId, c(event$lng, event$lat))))
			# update feature
			eval(parse(text=toc$plotFeature(toc$activeId, highlight=editCol)))
		})
	})
	
	# add a coordinate on geojson click
	observe({
		event = input$map_geojson_click	
		if (is.null(event) | grepl("base_",toc$activeId))
			return()
		if  (!(toc$tool %in% c(2:5) & toc$activeId!="-9999") | (toc$tool==2))
			return()
		isolate({
			#  create new feature if point
			if (toc$tool==2) {
				eval(parse(text=toc$reset()))
				toc$newPoint()
			}
			# add coordinate and marker
			eval(parse(text=toc$addCoordinate(toc$activeId, c(event$clicklng, event$clicklat))))
			# update feature
			eval(parse(text=toc$plotFeature(toc$activeId, highlight=editCol)))
		})
	})
	
	# remove a coordinate
	observe({
		event = input$map_marker_click
		if (!is.null(event) & toc$tool %in% 2:5 & toc$activeId!="-9999") {
			if (grepl("marker_", event$id) & !grepl("base_",event$id)) {
				isolate({
					# remove coordinate
					eval(parse(text=toc$removeCoordinate(toc$activeId, sub("marker_","",event$id))))
					if (toc$featureLST[[as.character(toc$activeId)]]$type=="Point") {
						# if point remove point	
						eval(parse(text=toc$removeFeature(toc$activeId)))
						toc$activeId<<-"-9999"
					} else {
						# if line or polygon remove coordinate and marker
						eval(parse(text=toc$plotFeature(toc$activeId, highlight=editCol)))
					}
				})
			}
		}
	})
	# start editing a point feature
	observe({
		event = input$map_marker_click
		if (!is.null(event) & toc$tool==5 & toc$activeId=="-9999") {
			if (!grepl("marker_", event$id) & !grepl("base_",event$id)) {
				# select layer
				isolate({
					# select layer
					eval(parse(text=toc$startEditFeature(event$id)))
					# update feature
					eval(parse(text=toc$plotFeature(event$id, highlight=editCol)))
				})
			}
		}
	})
	# start editing a polygon or line feature
	observe({
		event = input$map_geojson_click
		if (!is.null(event) & toc$tool==5 & toc$activeId=="-9999") {
			if(!grepl("base_",event$id)) {		
				# select layer
				isolate({
					# select layer
					eval(parse(text=toc$startEditFeature(event$id)))
					# update feature
					eval(parse(text=toc$plotFeature(event$id, highlight=editCol)))
				})
			}
		}
	})

	## remove layer observer
	observe({
		event = input$map_geojson_click
		if (is.null(event))
			event = input$map_marker_click
		if (is.null(event) | toc$tool!=7)
			return()
		isolate({
			if (!grepl("base_",event$id) & !grepl("base_",toc$activeId)) {
				# update polygons
				eval(parse(text=toc$removeFeature(as.character(event$id))))
			}
		})
	})

	## download button observer
	observe({
		if (input$downloadBtn==0)
			return()
		isolate({
			# init
			session$sendCustomMessage("disable_button",list(btn="downloadBtn"))
			alert=NULL
			if (toc$activeId!="-9999") {
				eval(parse(text=toc$stopEditFeature()))
			}
			toc$garbageCleaner()
			toc$removeOldFiles()
		
			# main
			session$sendCustomMessage("download_file",list(message=toc$download()))
			# update button
			session$sendCustomMessage("enable_button",list(btn="downloadBtn"))		
		})
	})
	
	## email button observer
	observe({
		if (input$emailBtn==0)
			return()
		isolate({
			### if custom email
			if (!is.null(toc$args$firstname) & !is.null(toc$args$lastname) & !is.null(toc$args$emailaddress)) {
				# init
				session$sendCustomMessage("enable_button",list(btn="emailBtn"))
						alert=NULL
				if (toc$activeId!="-9999") {
					eval(parse(text=toc$stopEditFeature()))
				}
				toc$garbageCleaner()
				toc$removeOldFiles()
			
				# main
				if (!toc$args$emailaddress %in% emailBlockList & length(toc$featureLST)>0) {
					try(toc$export(toc$args$firstname, toc$args$lastname, toc$args$emailaddress, ""))
				}
				
				# post
				session$sendCustomMessage("disable_button",list(btn="emailBtn"))			 		 
			} else {
				toggleModal(session, "emailMdl")
			}
		})
	})

	## send email button observer
	observe({
		if (input$sendEmailBtn==0)
			return()
		isolate({
			# init
			session$sendCustomMessage("disable_button",list(btn="sendEmailBtn"))
			alert=NULL
			if (toc$activeId!="-9999") {
				eval(parse(text=toc$stopEditFeature()))
			}
			toc$garbageCleaner()
			toc$removeOldFiles()
			
			# main
			x=list("First Name"=input$firstName, "Last Name"=input$lastName, "Email Address"=input$emailAddress)
			if (length(toc$featureLST)==0) {
				alert=list(text="No spatial data!",type="danger")
			} else {
				if (input$emailAddress %in% emailBlockList) {
					alert=list(text="This email address has been blocked!",type="danger")
				} else if (all(sapply(x, nchar)>0)) {
					# save shapefiles
					x=try(toc$export(x[[1]], x[[2]], x[[3]], input$emailtxt))
					if (inherits(x,"try-error")) {
						alert=list(text="Error processing data!",type="danger")
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
		})
	})
})




