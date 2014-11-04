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
	
	# generate program version number
	output$program_version=renderText({program_version})
	
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
	# annotate button observer 
	observe({
		if (input$toolBtn6==0 & toc$tool==1)
			return()
		isolate({
			# update annotation
			toc$addAnnotation(toc$activeId,input$annotationTxt)			
			# update popup
			eval(parse(text=toc$featureLST[[toc$activeId]]$addAnnotation()))
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
	observe({
		print(1)
		event = input$map_marker_click
		print(2)
		if (is.null(event))
			event = input$map_geojson_click
		cat("start event\n")	
		cat("lat",event$lat,"\n")
		cat("lat",event$lon,"\n")
		cat("clicklat",event$clicklat,"\n")
		cat("clicklon",event$clicklon,"\n")
		cat("end event\n")
			
		
		print(3)
		if (is.null(event) | toc$tool!=1)
			return()
		print(4)
		isolate({
			# reset
			eval(parse(text=toc$reset()))
			# add popup
			eval(parse(text=toc$selectFeature(event$id)))
			session$sendInputMessage("annotationTxt", list(value=toc$featureLST[[toc$activeId]]$annotation))
			updateButton(session, "toolBtn6", disabled=FALSE)
			session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('disabled',false)"))
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
			updateButton(session, "toolBtn6", disabled=TRUE)
			session$sendCustomMessage(type="jsCode",list(code="$('#annotationTxt').prop('disabled',true)"))
		})
	})
	
	## edit layer observer
	# start editing a point feature
	observe({
		event = input$map_marker_click
		if (!is.null(event) & toc$tool==5 & toc$activeId=="-9999") {
			if (!grepl("marker_", event$id)) {
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
			# select layer
			isolate({
				# select layer
				eval(parse(text=toc$startEditFeature(event$id)))
				# update feature
				eval(parse(text=toc$plotFeature(event$id, highlight=editCol)))
			})
		}
	})

	# add a coordinate
	observe({
		event = input$map_geojson_click
		if (is.null(event))
			event= input$map_click
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
	
	# remove a coordinate
	observe({
		event = input$map_marker_click
		if (!is.null(event) & toc$tool %in% 2:5 & toc$activeId!="-9999") {
			if (grepl("marker_", event$id)) {
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

	## remove layer observer
	observe({
		event = input$map_geojson_click
		if (is.null(event))
			event = input$map_marker_click
		if (is.null(event) | toc$tool!=7)
			return()
		isolate({
			# update polygons
			eval(parse(text=toc$removeFeature(as.character(event$id))))
		})
	})
	
	## save button observer
	observe({
		if (input$saveBtn==0)
			return()
		isolate({
			createAlert(session, inputId = "alertAchr",
				message = "Shh, I'm thinking...",
				type = "warning",
				dismiss = TRUE,
				block = FALSE,
				append = FALSE
			)
		})
	})
	
	## export button observer
	observe({
		if (input$saveBtn==0)
			return()
		isolate({
			# init
			if (toc$activeId!="-9999") {
				eval(parse(text=toc$stopEditFeature()))
			}
			toc$garbageCleaner()
			
			# main
			x=list("First Name"=input$firstName, "Last Name"=input$lastName, "Email Address"=input$emailAddress)
			if (length(toc$featureLST)==0) {
				alert=list(text="No spatial data!",type="danger")
			} else {
				if (all(sapply(x, nchar)>0)) {
					# save shapefiles
					x=try(toc$export(x[[1]], x[[2]], x[[3]], input$emailtxt))
					if (!inherits(x,"try-error")) {
						alert=list(text="Data saved and email notification sent!",type="success")
					} else {
						alert=list(text="Error processing data!",type="danger")
					}
				} else {
					y=which(sapply(x, nchar)==0)
					if (length(y)==1) {
						alert=list(text=paste0(names(x)[y], " field is incomplete!"),type="danger")
					} else {
						alert=list(text=paste0(paste(names(x)[], collapse=" and "), " fields are incomplete!"),type="danger")
					}
				}
			}
			# create alert
			createAlert(session, inputId = "alertAchr",
				message = alert$text,
				type = alert$type,
				dismiss = TRUE,
				block = FALSE,
				append = FALSE
			)
		})
	})
})


