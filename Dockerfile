FROM r-base

MAINTAINER Jeffrey O Hanson "jeffrey.hanson@uqconnect.edu.au"

RUN apt-get update && apt-get install -y --allow-downgrades \
	sudo \
	gdebi-core \
	pandoc \
	pandoc-citeproc \
	libcurl4-gnutls-dev \
	libcairo2-dev/unstable \
	libxt-dev \
	libssl-dev \
	libssh2-1-dev \
	gdal-bin \
	libgdal-dev \
	libproj-dev \
	libgeos-dev \
	libgeos-c1v5 \
	libgeotiff-dev \
	libtiff-dev \
	libtiff5=4.0.7-1

RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
	VERSION=$(cat version.txt) && \
	wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
	gdebi -n ss-latest.deb && \
	rm -f version.txt ss-latest.deb
 
RUN R -e "install.packages(c('ghit', 'rgdal', 'shiny', 'rgeos', 'Hmisc', 'RColorBrewer', 'fortunes', 'shinyBS', 'RcppTOML', 'RJSONIO', repos='https://cran.rstudio.com/'))"

RUN R -e  "ghit::install_github('jeffreyhanson/leaflet-shiny')"

COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

COPY app/* /srv/shiny-server/

RUN mkdir -p /var/log/shiny-server

RUN chown -R shiny.shiny /var/log/shiny-server

EXPOSE 80

COPY shiny-server.sh /usr/bin/shiny-server.sh

RUN chmod +x /usr/bin/shiny-server.sh

CMD ["/usr/bin/shiny-server.sh"]
