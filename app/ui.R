library(leaflet)

shinyUI(basicPage(
	# load styles and js scripts
	tags$head(
		includeScript('www/google-analytics.js'),
		includeScript('www/js-interface.js'),
		includeCSS('www/main-styles.css'),
		tags$link(rel="stylesheet", type="text/css", href="//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css")
	),
	
	# leaflet map
	div(class="map-wrapper",
		leafletMap(
			"map", "100%", "100%",
			initialTileLayer = 'GOOGLE',
			initialTileLayerAttribution =  HTML(''),
			options=list(
				center = c(-26.335955, 134.614984),
				zoom = 4,
				maxBounds = list(list(-90, -180), list(90, 180))
			)
		),
		div(class="button-wrapper btn-group sbs-button-group",
			bsButton('infoBtn', icon('info')),
			bsButton('helpBtn', icon('question')),
			bsButton('downloadBtn', icon('download')),
			bsButton('emailBtn', icon('envelope-o'))
		),
		bsTooltip("infoBtn", "Information.", placement = "bottom", trigger = "hover"),
		bsTooltip("helpBtn", "Help.", placement = "bottom", trigger = "hover"),
		bsTooltip("downloadBtn", "Download data to computer.", placement = "bottom", trigger = "hover"),
		bsTooltip("emailBtn", "Email data to friend.", placement = "bottom", trigger = "hover")
	),
		
	# email modal
	bsModal("emailMdl", "Send Data", trigger="nonexistantbtn",
	
	  # tag head 
		tagList(
			tags$head(
				tags$script(type="text/javascript", src = "busy.js")
			),
			tags$div(class="row-fluid",
				fluidRow(
					column(width=6,
						textInput("firstName", "First Name", value = ""),
						br(),
						textInput("lastName", "Last Name", value = ""),
						br(),
						textInput("emailAddress", "Friend's Email Address", value = ""),
						br(),
						br(),
						div(style="position: relative; left: 25%;",
								bsButton("sendEmailBtn", label="Send Data", style="primary")
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
				),
				fluidRow(
					bsAlert("alertAchr")
				)
			)
		)
	),
	
	# help modal
	bsModal("helpMdl", "Help", trigger="helpBtn",
		tags$div(class="row-fluid",
		bsCollapse(multiple = FALSE, open = "helpPanel1", id = "helpCollapse",
			bsCollapsePanel(
				"What's your deal?", 
				HTML("
				
				<p>Expert elicitation is an integral component of conservation science (<a href=\"https://onlinelibrary.wiley.com/doi/10.1111/j.1523-1739.2011.01806.x/abstract?deniedAccessCustomisedMessage=&userIsAuthenticated=false\" target=\"_blank\">Martin et al. 2012</a>). We wanted to provide researchers with a simple platform to elicit spatially explicit data from experts. Mapotron is <a href=\"https://github.com/paleo13/mapotron\" target=\"_blank\">open source</a> and free to use for non-commercial purposes.</p>
				
				<p>If you have any questions on how to use Mapotron, want to request new features, or wish to contribute base layer datasets, please <a href=\"javascript:location='mailto:jeffrey.hanson@uqconnect.edu.au';void 0\">contact us</a>.</p>
				
				<p>If you used Mapotron to collect data, please cite this software:</p>",
				"<p>",paste0("Hanson, J.O., Watts M.E., Barnes M., Ringma, J. & Beher, J. (2014) Mapotron. Version ", program_version, ". URL ",app.params.LST[['application.url']], "."),"</p>"),
				value="helpPanel1"),
			bsCollapsePanel(
				"How can I navigate to a particular location?", 
				tags$div(class="row-fluid",
					"Click and drag the mouse to pan around the map, and use the scroll wheel on your mouse to zoom in and out. Additionally, if you know the name of a place you wish to navigate to (eg. Brisbane): click on the geocoder icon (",
					suppressWarnings(bsButton("geocoder_help", img(src="icons/geocoderBtn.png", height=20, width=20))),
					"), type in the place name, and press the enter key."
				),
				value="helpPanel2"
			),
			bsCollapsePanel(
				"How do I draw new features?", 
				tags$div(class="row-fluid",
					"You can draw points(",
					suppressWarnings(bsButton("pointBtn_help", img(src="icons/pointBtn.png", height=20, width=20))),
					"), lines (",
					suppressWarnings(bsButton("lineBtn_help", img(src="icons/lineBtn.png", height=20, width=20))),
					"), polygons (",
					suppressWarnings(bsButton("polygonBtn_help", img(src="icons/polygonBtn.png", height=20, width=20))),
					"), rectangles (",
					suppressWarnings(bsButton("rectangleBtn_help", img(src="icons/rectangleBtn.png", height=20, width=20))),
					"), circles (",
					suppressWarnings(bsButton("circleBtn_help", img(src="icons/circleBtn.png", height=20, width=20))),
					"by clicking on one of these buttons, and then clicking on the map. Each click will add a new point or add vertex to a line or polygon feature."
				),
				value="helpPanel3"
			),
			bsCollapsePanel(
				"How do I edit or delete existing features?", 
				tags$div(class="row-fluid",
					"Click on the edit button(",
					suppressWarnings(bsButton("editBtn_help", img(src="icons/editBtn.png", height=20, width=20))),
					"), and then move points/vertices. Click 'Save' if you wish to keep these edits or 'cancel' if you wish to undo these changes. Click on the delete button (",
					suppressWarnings(bsButton("editBtn_help", img(src="icons/deleteBtn.png", height=20, width=20))),
					"), and then click on a feature to remove it. Similar to the edit button, click 'Save' if you wish to keep these changes, or 'cancel' to undo them."
				),
				value="helpPanel4"
			),
			bsCollapsePanel(
				"How can I label features?", 
				tags$div(class="row-fluid",
					"Right click on a feature and a textbox will appear. Type your label into this textbox and press enter to save."
				),
				value="helpPanel5"
			),
			bsCollapsePanel(
				"I've finished making the data, what now?", 
				tags$div(class="row-fluid",
					"You can download a zipfile containing data by clicking on the download button (",
					bsButton("downloadBtn_help", label=img(src="icons/downloadBtn.png", height=20, width=20)),
					"). Alternatively, you can send this data to a colleague, by clicking on the email button (",
					bsButton("emailBtn_help", label=img(src="icons/emailBtn.png", height=20, width=20)),
					"), filling in the text boxes, and clicking on the send data button(",
					bsButton("sendEmailBtn_help", label="Send Data", style="primary"),
					")."
				),
				value="helpPanel7"
			),
			bsCollapsePanel(
				"Some of the buttons don't work and/or the interface looks really stupid!", 
				tags$div(class="row-fluid",HTML(
					"<p>Mapotron was tested using <a href=\"https://www.google.com/chrome/\" target=\"_blank\">Google Chrome</a>. Please use <a href=\"https://www.google.com/chrome/\" target=\"_blank\">Google Chrome</a>.  We cannot guarantee that Mapotron will work with any other web browser; we do not plan to explicitly accommodate other web browsers in the near future.</p>
					<p>If you are using Google Chrome and encounter issues, please <a href=\"mailto:jeffrey.hanson@uqconnect.edu.au\">contact us</a>.</p>"
				)),
				value="helpPanel8"
			),
			bsCollapsePanel(
				"How can I embed Mapotron in my survey?", 
				tags$div(class="row-fluid",HTML(
					paste0("<p> You can embed Mapotron in a web page using the following html code:</p>
					<pre><code>&lt;iframe src=\"",app.params.LST[['application.url']],"\" style=\"border: none; width: 440px; height: 500px\">&lt;/iframe></code></pre>
					<p>You can change the <code>width</code> and <code>height</code> arguments to change the size of Mapotron in your web page.")
				)),
				value="helpPanel9"
			),
			bsCollapsePanel(
				"How can I customise Mapotron for my survey?", 
				tags$div(class="row-fluid",HTML(
					paste0(
						"<p>You can modify the url to send commands to Mapotron.</p>
						<ul>
							<li>
								<p>You can specify latitude, longitude and zoom level parameters to set the starting location:</p>
								<pre><code>",app.params.LST[['application.url']],"?lng=-27.56&lat=140.5&zoom=5</code></pre>
							</li>
							<li>
								<p>You can specify the first name, last name, email address, and message parameters.
								Mapotron will automatically save the data and send a notification email when these parameters are supplied. Note the email button (",suppressWarnings(bsButton("emailBtn_help", img(src="icons/emailBtn.png", height=20, width=20))),") can still be used to send the notification.
								You can use the message parameter to store metadata since messages are stored in the shapefiles' attribute tables. For example, if you have multiple questions in your survey, each with a separate instance of Mapotron, you can use the message parameter to associate each feature with its corresponding question:</p>
								<pre><code>",app.params.LST[['application.url']],"?firstname=Greg&lastname=McGreggorson&emailaddress=fakemcfakeerson@fakemail.com&message=question1</code></pre>
							</li>
						</ul>
						"
					)
				)),
				value="helpPanel10"
			)
		)
	)), 
		
	# about modal
	bsModal("infoMdl", "About", trigger="infoBtn",
		tags$div(class="row-fluid",
			column(
				fluidRow(
					wellPanel(
						h4("Development Team"),
						HTML("<p style=\"font-size:17px\" align=\"center\">Jeffrey O. Hanson</p>"),
						HTML("<p style=\"font-size:17px\" align=\"center\">Matthew E. Watts</p>"),
						HTML("<p style=\"font-size:17px\" align=\"center\">Megan Barnes</p>"),
						HTML("<p style=\"font-size:17px\" align=\"center\">Jeremy Ringma</p>"),
						HTML("<p style=\"font-size:17px\" align=\"center\">Jutta Beher</p>")
					),
					wellPanel(
						h4("Program Version"),
						HTML(paste0("<p style=\"font-size:17px\" align=\"center\">",program_version,"</p>"))
					)
				),
				width=5
			),
			column(wellPanel(
				h4("Credits"),
					HTML("
						<p>We thank the following people for their software. Please contact us if you should be added to this list!</p>
						<ul>
							<li>Agafonkin, V. (2014) <a href=\"https://leafletjs.com/\" target=\"_blank\">leafet.</a></li>
							<li>Bailey, E. (2014) <a href=\"https://github.com/ebailey78/shinyBS\" target=\"_blank\">shinyBS: Twitter Bootstrap Components for Shiny.</a> R package version 0.25.</li>
							<li>Bivand, R., Keitt, T. and Rowlingson, B. (2014) <a href=\"https://CRAN.R-project.org/package=rgdal\" target=\"_blank\">rgdal: Bindings for the Geospatial Data Abstraction Library.</a> R package version  0.8-16.</li>
							<li>Cheng, J. (2013) <a href=\"https://github.com/jcheng5/leaflet-shiny\" target=\"_blank\">leaflet: Interactive map component for Shiny, using Leaflet.</a> R package version 1.0.</li>
							<li>Esri (2014) <a href=\"https://github.com/Esri/esri-leaflet\" target=\"_blank\">Esri Leaflet.</a> Release Candidate 4.</li>
							<li>Friedman, A.B. (2014) <a href=\"https://CRAN.R-project.org/package=taRifx.geo\" target=\"_blank\">taRifx.geo: Collection of various spatial functions.</a> R package version 1.0.6.</li>
							<li>Google (2014) <a href=\"https://developers.google.com/maps/documentation/\" target=\"_blank\">Google Maps JavaScript API.</a> Version 3.</li>
							<li>Grundy, D. (2014) <a href=\"https://github.com/FortAwesome/Font-Awesome\" target=\"_blank\">Font Awesome.</a> Version 4.2.0.</li>
							<li>Harrell, F.E., Dupont, C. and others. (2014) <a href=\"https://CRAN.R-project.org/package=Hmisc\" target=\"_blank\">Hmisc: Harrell Miscellaneous.</a> R package version  3.14-4.</li>
							<li>IBRA (2012) <a href=\"http://www.environment.gov.au/topics/land/national-reserve-system/science-maps-and-data/australias-bioregions-ibra\" target=\"_blank\"> Interim Biogeographic Regionalisation for Australia, version 7 (IBRA bioregions) (Commonwealth of  Australia:  Canberra)</a>. Accessed 1 November 2014.</li>
							<li>Liedman, P. (2014) <a href=\"https://github.com/perliedman/leaflet-control-geocoder\" target=\"_blank\">Leaflet Control Geocoder.</a> version 1.0.0.</li>
							<li>Mapbox (2014) <a href=\"https://www.mapbox.com/maki/\" target=\"_blank\">MakiMarkers.</a> Version 0.4.5.</li>
							<li>Neuwirth, E. (2011) <a href=\"https://CRAN.R-project.org/package=RColorBrewer\" target=\"_blank\">RColorBrewer: ColorBrewer palettes.</a> R package version 1.0-5.</li>
							<li>Premraj, R. (2014) <a href=\"mailR: A utility to send emails from R.\" target=\"_blank\">https://github.com/rpremraj/mailR</a> R package version 0.3.1.</li>
							<li>R Core Team (2014) <a href=\"https://www.R-project.org/\" target=\"_blank\"> R: A language and environment for statistical computing.</a> R Foundation for Statistical Computing, Vienna, Austria.</li>
							<li>RStudio and Inc. (2014) <a href=\"https://CRAN.R-project.org/package=shiny\" target=\"_blank\">shiny: Web Application Framework for R.</a> R package version 0.10.2.1.</li>
							<li>Seppi, J. (2014) <a href=\"https://github.com/jseppi/Leaflet.MakiMarkers\" target=\"_blank\">Leaflet MakiMarkers.</a></li>
							<li>Shamrov, P. (2014) <a href=\"https://github.com/shramov/leaflet-plugins\" target=\"_blank\">Leaflet Plugins.</a> Version 1.2.0.</li>
							<li>Toye, J. (2014) <a href=\"https://github.com/Leaflet/Leaflet.draw\" target=\"_blank\">Leaflet Draw.</a> Version 0.2.3.</li>
							<li>Toye, J. (2014) <a href=\"https://github.com/Leaflet/Leaflet.label\" target=\"_blank\">Leaflet Label.</a> Version 0.2.1.</li>
					</ul>
					")
			), width=7)
		)
	)
))


