all: sqlc tsc build

check:
	go vet ./...
	staticcheck ./...
		
tsc: assets/main.js
	tsc assets/main.ts

sqlc: queries.sql schema.sql
	sqlc generate

build:
	go build

run: sqlc build
	./gostart -name startdev -db ./test.db
