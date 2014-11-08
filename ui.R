library(leaflet)
library(ShinyDash)

shinyUI(basicPage(
	# navbar
	bsNavBar("navBar", brand="Mapotron", inverse=TRUE, fixed=TRUE,
		bsNavDropDown("baseSel", label="Base Layer", choices=c("None"="-9999")),
		suppressWarnings(bsActionButton("toolBtn1", img(src="icons/toolBtn1_white.png", height=20, width=20), style="primary")),
		tagList(
			div(style="display:inline-block; position: relative; top: 6px; bottom: 0; left: 0; right 0; padding: 0;",
				tags$input(id = "annotationTxt", type="text", value="", class="enterTextInput")
			)
		),
		suppressWarnings(bsActionButton("toolBtn2", img(src="icons/toolBtn2_white.png", height=20, width=20), style="inverse")),
		suppressWarnings(bsActionButton("toolBtn3", img(src="icons/toolBtn3_white.png", height=20, width=20), style="inverse")),
		suppressWarnings(bsActionButton("toolBtn4", img(src="icons/toolBtn4_white.png", height=20, width=20), style="inverse")),
		bsNavDivider(),
		suppressWarnings(bsActionButton("toolBtn5", img(src="icons/toolBtn5_white.png", height=20, width=20), style="inverse")),
		suppressWarnings(bsActionButton("toolBtn7", img(src="icons/toolBtn7_white.png", height=20, width=20), style="inverse")),
		rightItems=list(
			tagList(div(style="display:inline-block; position: relative; top: 3px; color: #999; font-size:130%;", tags$p("Take me to "))),
			tagList(
				div(style="display:inline-block; position: relative; top: 6px; bottom: 0; left: 0; right 0; padding: 0;",
					tags$input(id = "geocodeTxt", type="text", value="", class="enterTextInput")
				)
			),
			bsButton("helpBtn", img(src="icons/help_white.png", height=20, width=20), style="inverse"),
			suppressWarnings(bsActionButton("downloadBtn", img(src="icons/download_white.png", height=20, width=20), style="inverse")),
			bsButton("emailBtn", img(src="icons/email_white.png", height=20, width=20), style="inverse")
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
	bsTooltip("toolBtn1", "navigation + select feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn2", "add point feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn3", "add line feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn4", "add polygon feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn5", "edit feature", placement = "bottom", trigger = "hover"),
	bsTooltip("annotationTxt", "annotate feature", placement = "bottom", trigger = "hover"),
	bsTooltip("toolBtn7", "remove feature", placement = "bottom", trigger = "hover"),
	
	# save modal
	bsModal("saveMdl", "Send Data", trigger="emailBtn",
	
	  # tag head 
		tagList(
			tags$head(
			tags$link(rel="stylesheet", type="text/css",href="style.css"),
			tags$script(type="text/javascript", src = "busy.js")
			),
			tags$div(class="row-fluid",
				fluidRow(
					column(width=6,
						textInput("firstName", "First Name", value = ""),
						br(),
						textInput("lastName", "Last Name", value = ""),
						br(),
						textInput("emailAddress", "Colleague's Email Address", value = ""),
						br(),
						br(),
						div(style="position: relative; left: 25%;",
								bsActionButton("sendEmailBtn", label="Send Data", style="primary")
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
		bsCollapse(multiple = FALSE, open = "col1", id = "helpCollapse",
			bsCollapsePanel(
				"What's your deal?", 
				HTML("
				
				<p>Expert elicitation is an integral component of conservation science (<a href=\"http://onlinelibrary.wiley.com/doi/10.1111/j.1523-1739.2011.01806.x/abstract?deniedAccessCustomisedMessage=&userIsAuthenticated=false\">Martin et al. 2012</a>). We wanted to provide researchers with a simple platform to elicit spatially explicit data from experts. Mapotron is <a href=\"https://github.com/paleo13/mapotron\">open source</a> and free to use for non-commercial purposes.</p>
				
				<p>If you have any questions on how to use Mapotron, want to request new features, or wish to contribute base layer datasets, please <a href=\"mailto:&#109;&#097;&#112;&#111;&#116;&#114;&#111;&#110;&#064;&#103;&#109;&#097;&#105;&#108;&#046;&#099;&#111;&#109\">contact us</a>.</p>
				
				<p>If you used Mapotron to collect data, please cite this software:</p>",
				"<p>",paste0("Hanson, J.O., Watts M.E., Barnes M., Ringma, J. & Beher, J. (2014) Mapotron. Version ", program_version, ". URL ",shinyurl, "."),"</p>"),
				id="col1", value="helpPanel1"),
			bsCollapsePanel(
				"How can I navigate to a particular location?", 
				tags$div(class="row-fluid",
					"Click on the navigate/select button(",
					suppressWarnings(bsActionButton("toolBtn1_help", img(src="icons/toolBtn1_white.png", height=20, width=20), style="inverse")),
					"), you can now click and drag the mouse to pan around the map. You can use the scroll wheel on your mouse to zoom in and out. If you know the latitude and longitude (eg. -27.454, 154.6767), or the name of the place (eg. Brisbane) type it into the text box on the top-right corner of the screen and hit enter."
				),
				id="col2", value="helpPanel2"
			),
			bsCollapsePanel(
				"How do I draw new features?", 
				tags$div(class="row-fluid",
					"You can draw points(",
					suppressWarnings(bsActionButton("toolBtn2_help", img(src="icons/toolBtn2_white.png", height=20, width=20), style="inverse")),
					"), lines (",
					suppressWarnings(bsActionButton("toolBtn3_help", img(src="icons/toolBtn3_white.png", height=20, width=20), style="inverse")),
					"), and polyogns (",
					suppressWarnings(bsActionButton("toolBtn4_help", img(src="icons/toolBtn4_white.png", height=20, width=20), style="inverse")),
					") by clicking on a new feature button, and then click on the map. Each click will add a new point or add vertex to a line or polygon feature."
				),
				id="col3", value="helpPanel3"
			),
			bsCollapsePanel(
				"How do I edit existing features?", 
				tags$div(class="row-fluid",
					"Click on the edit feature button(",
					suppressWarnings(bsActionButton("toolBtn5_help", img(src="icons/toolBtn5_white.png", height=20, width=20), style="inverse")),
					"), and then select a feature. Markers will appear over points or vertices of the feature, click on these markers to remove vertices or click on the map to add new vertices."
				),
				id="col4", value="helpPanel4"
			),				
			bsCollapsePanel(
				"How can I annotate features?", 
				tags$div(class="row-fluid",
					"Click on the navigate/select button",
					suppressWarnings(bsActionButton("toolBtn1_help", img(src="icons/toolBtn1_white.png", height=20, width=20), style="inverse")),
					", and click on a feature to select it. The feature will now have a cyan border. Type text into the text box on the top left corner of the screen, and press enter to save the annotation."
				),
				id="col5", value="helpPanel5"
			),
			bsCollapsePanel(
				"How do I remove existing features?", 
				tags$div(class="row-fluid",
					"Click on the remove feature button(",
					suppressWarnings(bsActionButton("toolBtn7_help", img(src="icons/toolBtn7_white.png", height=20, width=20), style="inverse")),
					"), and then click on a feature. Be careful: once you remove a feature there is no way to recover it."
				),
				id="col6", value="helpPanel6"
			),
			bsCollapsePanel(
				"I've finished making the data, what now?", 
				tags$div(class="row-fluid",
					"You can download a zipfile containing data by clicking on the download button (",
					bsButton("downloadBtn_help", img(src="icons/download_white.png", height=20, width=20), style="inverse"),	
					"). Alternatively, you can send this data to a colleague, by clicking on the email button (",
					bsButton("emailBtn_help", img(src="icons/email_white.png", height=20, width=20), style="inverse"),
					"), filling in the text boxes, and clicking on the send data button(",
					bsActionButton("sendEmailBtn_help", label="Send Data", style="primary"),
					")."
				),
				id="col7", value="helpPanel6"
			)
		)
	)), 
	
	
	
	# about modal
	bsModal("aboutMdl", "About", trigger="x",
		tags$div(class="row-fluid",
			column(
				fluidRow(
					wellPanel(
						h4("Development Team"),
						h6("Jeffrey Hanson"),
						h6("Matthew Watts"),
						h6("Megan Barnes"),
						h6("Jeremy Ringma"),
						h6("Jutta Beher")
					),
					wellPanel(
						h4("Program Version"),
						h5(textOutput("program_version"), align="center")
					)
				),
				width=5
			),
			column(wellPanel(
				h4("Attributions"),
					HTML("
						<ul>
						<li>Agafonkin, V. (2014) <a href=\"http://leafletjs.com/\">leafet</a></li>
						<li>Bailey, E. (2014) <a href=\"https://github.com/ebailey78/shinyBS\">shinyBS: Twitter Bootstrap Components for Shiny.</a> R package version 0.25.</li>
						<li>Bivand, R., Keitt, T. and Rowlingson, B. (2014) <a href=\"http://CRAN.R-project.org/package=rgdal\">rgdal: Bindings for the Geospatial Data Abstraction Library.</a> R package version  0.8-16.</li>
						<li>Cheng, J. (2013) <a href=\"leaflet: Interactive map component for Shiny, using Leaflet.\">https://github.com/jcheng5/leaflet-shiny</a> R package version 1.0.</li>
						<li>Friedman, A.B. (2014) <a href=\"http://CRAN.R-project.org/package=taRifx.geo\">taRifx.geo: Collection of various spatial functions.</a> R package version 1.0.6.</li>
						<li>Google (2014) <a href=\"https://developers.google.com/maps/documentation/geocoding/\">Geocoding API</a>. Version 3. 
						<li>Icons made by <a href=\"http://www.google.com\" title=\"Google\">Google</a> from <a href=\"http://www.flaticon.com\" title=\"Flaticon\">www.flaticon.com</a> is licensed under <a href=\"http://creativecommons.org/licenses/by/3.0/\" title=\"Creative Commons BY 3.0\">CC BY 3.0</a></li>
						<li>Mapbox (2014) <a href=\"https://www.mapbox.com/maki/\">MakiMarkers.</a> version 0.4.5.</li>
						<li>Neuwirth, E. (2011) <a href=\"http://CRAN.R-project.org/package=RColorBrewer\">RColorBrewer: ColorBrewer palettes</a>. R package version 1.0-5.</li>
						<li>Nychka, D., Furrer, R. and Sain, S. (2014) <a href=\"http://CRAN.R-project.org/package=fields\">fields: Tools for spatial data</a>. R package version 7.1.</li>
						<li>Premraj, R. (2014) <a href=\"mailR: A utility to send emails from R.\">https://github.com/rpremraj/mailR</a> R package version 0.3.1.</li>
						<li>R Core Team (2014) <a href=\"http://www.R-project.org/\"> R: A language and environment for statistical computing.</a> R Foundation for Statistical Computing, Vienna, Austria.</li>
						<li>RStudio and Inc. (2014) <a href=\"http://CRAN.R-project.org/package=shiny\">shiny: Web Application Framework for R.</a> R package version 0.10.2.1</li>
						<li>Seppi, J. (2014) <a href=\"https://github.com/jseppi/Leaflet.MakiMarkers\">Leaflet MakiMarkers</a></li>
					</ul>
					")
			), width=7)
		)
	),
	
	# map container html tags
	tags$head(
		tags$style("
			.mapContainer {
			  position: fixed;
			  top: 40px;
			  left: 0;
			  right: 0;
			  bottom: 0;
			  overflow: hidden;
			  padding: 0;
			}
		"), tags$script(HTML('
			Shiny.addCustomMessageHandler("jsCode",
				function(message) {
				  console.log(message)
				  eval(message.code);
				}
			  );

			Shiny.addCustomMessageHandler("enable_download_button", 
				function(message) {
					$("#downloadBtn").removeAttr("disabled");
				}
			);
			
			Shiny.addCustomMessageHandler("disable_download_button", 
				function(message) {
					$("#downloadBtn").prop(\"disabled\",true);
				}
			);

			Shiny.addCustomMessageHandler("enable_email_button", 
				function(message) {
					$("#sendEmailBtn").removeAttr("disabled");
				}
			);
			
			Shiny.addCustomMessageHandler("disable_email_button", 
				function(message) {
					$("#sendEmailBtn").prop(\"disabled\",true);
				}
			);
			
			Shiny.addCustomMessageHandler("download_file",
				function(message) {
					var link = document.createElement("a");
					link.download = "spatialdata.zip";
					link.href = message.message;
					link.click();
				}
			);
					
			var enterTextInputBinding = new Shiny.InputBinding();
				$.extend(enterTextInputBinding, {
				find: function(scope) {
					return $(scope).find(\'.enterTextInput\');
				},
				getId: function(el) {
					//return InputBinding.prototype.getId.call(this, el) || el.name;
					return $(el).attr(\'id\')
				},
				getValue: function(el) {
					return el.value;
				},
				setValue: function(el, value) {
					el.value = value;
				},
				subscribe: function(el, callback) {
					$(el).on(\'keyup.textInputBinding input.textInputBinding\', function(event) {
						if(event.keyCode == 13) { //if enter
							callback()
						}
					});	
				},
				unsubscribe: function(el) {
					$(el).off(\'.enterTextInputBinding\');
				},
				receiveMessage: function(el, data) {
					if (data.hasOwnProperty(\'value\'))
						this.setValue(el, data.value);
					if (data.hasOwnProperty(\'label\'))
						$(el).parent().find(\'label[for=\' + el.id + \']\').text(data.label);
					$(el).trigger(\'change\');
				},
				getState: function(el) {
					return {
						label: $(el).parent().find(\'label[for=\' + el.id + \']\').text(),
						value: el.value
					};
				},
				getRatePolicy: function() {
					return {
						policy: \'debounce\',
						delay: 250
					};
				}
            });
			
            Shiny.inputBindings.register(enterTextInputBinding, \'shiny.enterTextInput\');

				
			
		'))
	)
))


