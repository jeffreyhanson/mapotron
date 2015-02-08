# debugging computer code
# install('C:/Users/jeff/Documents/GitHub/leaflet-shiny')
shiny::runApp("C:/Users/jeff/Documents/GitHub/mapotron")

# deply on server

shinyapps::deployApp("C:/Users/jeff/Documents/GitHub/mapotron")
shinyapps::configureApp('mapotron', appDir = 'C:/Users/jeff/Documents/GitHub/mapotron', redeploy = TRUE, size = 'xlarge')
