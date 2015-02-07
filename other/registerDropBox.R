library(RCurl)
library(rDrop)
oauth_handle = getCurlHandle(verbose = TRUE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
oauth_cred = dropbox_auth('9et7i9n741l6qgq','6ddkpbnqbge6gwi', curl = oauth_handle)
save(oauth_handle, oauth_cred, file='C:/Users/jeff/Documents/GitHub/mapotron/other/dropbox.rda')


cat('ghghghgh', file.path(tempdir(), 'test.txt'))
dropbox_put(oauth_cred, tempdir(), tempdir(), oauth_handle)