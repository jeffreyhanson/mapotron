library(leaflet)
library(ShinyDash)

shinyUI(basicPage(
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
			bsActionButton('infoBtn', icon('info')),
			bsActionButton('helpBtn', icon('question')),
			bsActionButton('downloadBtn', icon('download')),
			bsActionButton('emailBtn', icon('envelope-o'))
		)
	),
		
	# email modal
	bsModal("emailMdl", "Send Data", trigger="nonexistantbtn",
	
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
				
				<p>Expert elicitation is an integral component of conservation science (<a href=\"https://onlinelibrary.wiley.com/doi/10.1111/j.1523-1739.2011.01806.x/abstract?deniedAccessCustomisedMessage=&userIsAuthenticated=false\" target=\"_blank\">Martin et al. 2012</a>). We wanted to provide researchers with a simple platform to elicit spatially explicit data from experts. Mapotron is <a href=\"https://github.com/paleo13/mapotron\" target=\"_blank\">open source</a> and free to use for non-commercial purposes.</p>
				
				<p>If you have any questions on how to use Mapotron, want to request new features, or wish to contribute base layer datasets, please <a href=\"mailto:&#109;&#097;&#112;&#111;&#116;&#114;&#111;&#110;&#064;&#103;&#109;&#097;&#105;&#108;&#046;&#099;&#111;&#109\">contact us</a>.</p>
				
				<p>If you used Mapotron to collect data, please cite this software:</p>",
				"<p>",paste0("Hanson, J.O., Watts M.E., Barnes M., Ringma, J. & Beher, J. (2014) Mapotron. Version ", program_version, ". URL ",shinyurl, "."),"</p>"),
				id="col1", value="helpPanel1"),
			bsCollapsePanel(
				"How can I navigate to a particular location?", 
				tags$div(class="row-fluid",
					"Click and drag the mouse to pan around the map, and use the scroll wheel on your mouse to zoom in and out. Additionally, if you know the name of a place you wish to navigate to (eg.Brisbane): click on the geocoder icon (",
					suppressWarnings(bsActionButton("geocoder_help", img(src="icons/geocoderBtn.png", height=20, width=20))),
					"), type in the place name, and press the enter key."
				),
				id="col2", value="helpPanel2"
			),
			bsCollapsePanel(
				"How do I draw new features?", 
				tags$div(class="row-fluid",
					"You can draw points(",
					suppressWarnings(bsActionButton("pointBtn_help", img(src="icons/pointBtn.png", height=20, width=20))),
					"), lines (",
					suppressWarnings(bsActionButton("lineBtn_help", img(src="icons/lineBtn.png", height=20, width=20))),
					"), polygons (",
					suppressWarnings(bsActionButton("polygonBtn_help", img(src="icons/polygonBtn.png", height=20, width=20))),
					"), rectangles (",
					suppressWarnings(bsActionButton("rectangleBtn_help", img(src="icons/rectangleBtn.png", height=20, width=20))),
					"), circles (",
					suppressWarnings(bsActionButton("circleBtn_help", img(src="icons/circleBtn.png", height=20, width=20))),
					"by clicking on one of these buttons, and then clicking on the map. Each click will add a new point or add vertex to a line or polygon feature."
				),
				id="col3", value="helpPanel3"
			),
			bsCollapsePanel(
				"How do I edit or delete existing features?", 
				tags$div(class="row-fluid",
					"Click on the edit button(",
					suppressWarnings(bsActionButton("editBtn_help", img(src="icons/editBtn.png", height=20, width=20))),
					"), and then move points/vertices. Click 'Save' if you wish to keep these edits or 'cancel' if you wish to undo these changes. Click on the delete button (",
					suppressWarnings(bsActionButton("editBtn_help", img(src="icons/deleteBtn.png", height=20, width=20))),
					"), and then click on a feature to remove it. Similar to the edit button, click 'Save' if you wish to keep these changes, or 'cancel' to undo them."
				),
				id="col4", value="helpPanel4"
			),				
			bsCollapsePanel(
				"How can I label features?", 
				tags$div(class="row-fluid",
					"Right click on a feature and a textbox will appear. Type your label into this textbox and press enter to save."
				),
				id="col5", value="helpPanel5"
			),
			bsCollapsePanel(
				"I've finished making the data, what now?", 
				tags$div(class="row-fluid",
					"You can download a zipfile containing data by clicking on the download button (",
					bsButton("downloadBtn_help", img(src="icons/downloadBtn.png", height=20, width=20)),	
					"). Alternatively, you can send this data to a colleague, by clicking on the email button (",
					bsButton("emailBtn_help", img(src="icons/emailBtn.png", height=20, width=20)),
					"), filling in the text boxes, and clicking on the send data button(",
					bsActionButton("sendEmailBtn_help", label="Send Data", style="primary"),
					")."
				),
				id="col7", value="helpPanel7"
			),
			bsCollapsePanel(
				"Some of the buttons don't work and/or the interface looks really stupid!", 
				tags$div(class="row-fluid",HTML(
					"<p>Mapotron was tested using <a href=\"https://www.google.com/chrome/\" target=\"_blank\">Google Chrome</a>. Please use <a href=\"https://www.google.com/chrome/\" target=\"_blank\">Google Chrome</a>.  We cannot guarantee that Mapotron will work with any other web browser; we do not plan to explicitly accommodate other web browsers in the near future.</p>
					<p>If you are using Google Chrome and encounter issues, please <a href=\"mailto:&#109;&#097;&#112;&#111;&#116;&#114;&#111;&#110;&#064;&#103;&#109;&#097;&#105;&#108;&#046;&#099;&#111;&#109\">contact us</a>.</p>"
				)),
				id="col8", value="helpPanel8"
			),
			bsCollapsePanel(
				"How can I embed Mapotron in my survey?", 
				tags$div(class="row-fluid",HTML(
					paste0("<p> You can embed Mapotron in a web page using the following html code:</p>
					<pre><code>&lt;iframe src=\"",shinyurl,"\" style=\"border: none; width: 440px; height: 500px\">&lt;/iframe></code></pre>
					<p>You can change the <code>width</code> and <code>height</code> arguments to change the size of Mapotron in your web page.")
				)),
				id="col9", value="helpPanel9"
			),
			bsCollapsePanel(
				"How can I customise Mapotron for my survey?", 
				tags$div(class="row-fluid",HTML(
					paste0(
						"<p>You can modify the url to send commands to Mapotron.</p>
						<ul>
							<li>
								<p>You can specify latitude, longitude and zoom level parameters to set the starting location:</p>
								<pre><code>",shinyurl,"?lng=-27.56&lat=140.5&zoom=5</code></pre>
							</li>
							<li>
								<p>You can specify the first name, last name, email address, and message parameters.
								Mapotron will automatically save the data and send a notification email when these parameters are supplied. Note the email button (",suppressWarnings(bsActionButton("emailBtn_help", img(src="icons/emailBtn.png", height=20, width=20))),") can still be used to send the notification.
								You can use the message parameter to store metadata since messages are stored in the shapefiles' attribute tables. For example, if you have multiple questions in your survey, each with a separate instance of Mapotron, you can use the message parameter to associate each feature with its corresponding question:</p>
								<pre><code>",shinyurl,"?firstname=Greg&lastname=McGreggorson&emailaddress=fakemcfakeerson@fakemail.com&message=question1</code></pre>
							</li>
						</ul>
						"
					)
				)),
				id="col10", value="helpPanel10"
			)
		)
	)), 
		
	# about modal
	bsModal("aboutMdl", "About", trigger="infoBtn",
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
							<li>Google (2014) <a href=\"https://developers.google.com/maps/documentation/\" target=\"_blank\">Google Maps JavaScript API.</a> Version 3. 
							<li>Harrell, F.E., Dupont, C. and others. (2014) <a href=\"https://CRAN.R-project.org/package=Hmisc\" target=\"_blank\">Hmisc: Harrell Miscellaneous.</a> R package version  3.14-4.</li>
							<li>Liedman, P. (2014) <a href=\"https://github.com/perliedman/leaflet-control-geocoder\" target=\"_blank\">Leaflet Control Geocoder.</a> version 1.0.0.</li>
							<li>Mapbox (2014) <a href=\"https://www.mapbox.com/maki/\" target=\"_blank\">MakiMarkers.</a> version 0.4.5.</li>
							<li>Montague, D. (2014) <a href=\"https://github.com/CliffCloud/Leaflet.EasyButton\" target=\"_blank\">Leaflet Easy Button.</a> version 0.</li>
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
	),
	
	# map container html tags
	tags$head(
		tags$style("
				
			pre  {
				background-color: #FCFCFC;
			}

			pre code{
				color: #FF1493;
			}
			
			code {
				color: #FF1493;
				background-color: #FCFCFC;
			}
		
			.map-wrapper {
			  position: fixed;
			  top: 0;
			  left: 0;
			  right: 0;
			  bottom: 0;
			  overflow: hidden;
			  padding: 0;
			}
			
			.button-wrapper {
				position: absolute;
				top: 0%;
				padding-left: 50%;
			}			
		"), 
		tags$link(rel="stylesheet", type="text/css", href="//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css"),
		tags$script(HTML('
			
			
			Shiny.addCustomMessageHandler("jsCode",
				function(message) {
				  console.log(message)
				  eval(message.code);
				}
			  );
		
			Shiny.addCustomMessageHandler("update_var",
				function(message) {
					eval(message.var + \' = \' + message.val);
				}
			  );
			
		
			var is_dirty=false;
			var auto_send=false;
			function exit_page(event) {
				if (is_dirty && !auto_send) {
					return \'You have made changes to the data without downloading or emailing it -- if you leave before performing either of these actions all data will be lost.\'
				}
			}
			window.onbeforeunload = exit_page;
			
			Shiny.addCustomMessageHandler("download_file",
				function(message) {
					var link = document.createElement("a");
					link.download = "spatialdata.zip";
					link.href = message.message;
					link.click();
				}
			);
			
			Shiny.addCustomMessageHandler("enable_button", 
				function(message) {
					$("#" + message.btn).removeAttr("disabled");
				}
			);
			
			Shiny.addCustomMessageHandler("disable_button", 
				function(message) {
					$("#" + message.btn).prop(\"disabled\",true);
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


