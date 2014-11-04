library(leaflet)
library(ShinyDash)

shinyUI(basicPage(
	# navbar
	bsNavBar("navBar", brand="Mapotron", inverse=TRUE, fixed=TRUE,
		bsNavDropDown("baseSel", label="Base Layer", choices=c("None"="-9999")),
		tagList(
			div(style="display:inline-block; position: relative; top: 6px; bottom: 0; left: 0; right 0; padding: 0;",
				tags$input(id = "annotationTxt", type="text", value="", class="input")
			)
		),
		suppressWarnings(bsActionButton("toolBtn5", img(src="icons/toolBtn5_white.png", height=20, width=20), style="inverse")),
		suppressWarnings(bsActionButton("toolBtn1", img(src="icons/toolBtn1_white.png", height=20, width=20), style="primary")),
		suppressWarnings(bsActionButton("toolBtn2", img(src="icons/toolBtn2_white.png", height=20, width=20), style="inverse")),
		suppressWarnings(bsActionButton("toolBtn3", img(src="icons/toolBtn3_white.png", height=20, width=20), style="inverse")),
		suppressWarnings(bsActionButton("toolBtn4", img(src="icons/toolBtn4_white.png", height=20, width=20), style="inverse")),
		suppressWarnings(bsActionButton("toolBtn6", img(src="icons/toolBtn6_white.png", height=20, width=20), style="inverse")),		
		suppressWarnings(bsActionButton("toolBtn7", img(src="icons/toolBtn7_white.png", height=20, width=20), style="inverse")),
		rightItems=list(
			bsButton("helpBtn", img(src="icons/help_white.png", height=20, width=20), style="inverse"),
			bsButton("sendBtn", img(src="icons/email_white.png", height=20, width=20), style="inverse")
		)
	),
	
	# leaflet map
	div(class="mapContainer",
		leafletMap(
			"map", "100%", "100%",
			initialTileLayer = 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
			initialTileLayerAttribution =  HTML('© OpenStreetMap contributors, CC-BY-SA'),
			options=list(
				center = c(-26.335955, 134.614984),
				zoom = 4,
				maxBounds = list(list(-90, -180), list(90, 180))
			)
		)
	),
	
	# tool tips
	bsTooltip("toolBtn1", "navigation + show annotation", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn2", "add point feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn3", "add line feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn4", "add polygon feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn5", "edit feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn6", "add annotation", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn7", "remove feature", placement = "bottom", trigger = "hover"),
	
	# save modal
	bsModal("saveMdl", "Send Data", trigger="sendBtn",
	
	  # tag head 
		tagList(
			tags$head(
			tags$link(rel="stylesheet", type="text/css",href="style.css"),
			tags$script(type="text/javascript", src = "busy.js")
			),
			tags$div(class="row-fluid",
				column(width=6,
					textInput("firstName", "First Name", value = ""),
					br(),
					textInput("lastName", "Last Name", value = ""),
					br(),
					textInput("emailAddress", "Researcher's Email Address", value = ""),
					br(),
					br(),
					div(style="position: relative; left: 25%;",
							bsActionButton("saveBtn", label="Save Data", style="primary")
					),
					div(class = "busy",  
					  p("Calculation in progress.."), 
					  img(src="icons/ajax-loader.gif")
					)
				),
				column(width=4,
					tagList(
						div(style="position: relative; top: 0px; bottom: 0; left: 0px; right 0; padding: 0;",
							tags$label("Message"),
							tags$textarea(id="emailtxt", rows=12, cols=20, "")
						)
					)
				)
			)
				
		)
	),
	
	# help modal
	bsModal("helpMdl", "About", trigger="helpBtn",
		tags$div(class="row-fluid",
			column(wellPanel(
				h4("Help"),
				fluidRow(
					column(bsActionButton("mapBtn_help", img(src="icons/toolBtn1_white.png", height=20, width=20), style="inverse"),width=3),
					column(h6("navigation + show annotations"),width=9)
				),
				fluidRow(
					column(bsActionButton("addPointBtn_help", img(src="icons/toolBtn2_white.png", height=20, width=20), style="inverse"),width=3),
					column(h6("add new point features"),width=7)
				),
				fluidRow(
					column(bsActionButton("addLineBtn_help", img(src="icons/toolBtn3_white.png", height=20, width=20), style="inverse"),width=3),
					column(h6("new line feature"),width=7)
				),
				fluidRow(
					column(bsActionButton("addPolygonBtn_help", img(src="icons/toolBtn4_white.png", height=20, width=20), style="inverse"),width=3),
					column(h6("new polygon feature"),width=7)
				),
				fluidRow(
					column(bsActionButton("editBtn_help", img(src="icons/toolBtn5_white.png", height=20, width=20), style="inverse"),width=3),
					column(h6("edit existing feature"),width=7)
				),
				fluidRow(
					column(bsActionButton("annotateBtn_help", img(src="icons/toolBtn6_white.png", height=20, width=20), style="inverse"),width=3),
					column(h6("annotate existing feature"),width=7)
				),
				fluidRow(
					column(bsActionButton("removeBtn_help", img(src="icons/toolBtn7_white.png", height=20, width=20), style="inverse"),width=3),
					column(h6("remove existing feature"),width=7)
				),
				fluidRow(
					column(bsActionButton("saveBtn", label="Send Data", style="primary"),width=5),
					column(h6("email data"),width=4)
				)
			), width=7),
			column(
				fluidRow(
					wellPanel(
						h4("Development Team"),
						h6("Jeffrey Hanson"),
						h6("Matthew Watts"),
						h6("Megan Barnes"),
						h6("Jutta Beher")
					),
					wellPanel(
						h4("Program Version"),
						h5(textOutput("program_version"), align="center")
					)
				),
				width=5
			)
		)
	),
	
	# map container html tags
	tags$head(tags$style("
    .mapContainer {
      position: fixed;
      top: 40px;
      left: 0;
      right: 0;
      bottom: 0;
      overflow: hidden;
      padding: 0;
    },
  "))
))


