all:
	gofmt -w *.go
	docker-compose stop
	docker-compose build
	docker-compose up
