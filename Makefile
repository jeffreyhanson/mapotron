all: build run

clean:
	@R --slave -e "unlink(dir('app/data/users', '^user.*', full.names=TRUE), recursive=TRUE, force=TRUE)"

test:
	R --slave -e "shiny::runApp('app', port=5922)"

run:
	docker run -v /data:/host/data --rm -p 80:80 jeffreyhanson/mapotron
build:
	docker build -t jeffreyhanson/mapotron

.PHONY: build all test
