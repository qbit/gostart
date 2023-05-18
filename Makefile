all: sqlc elm build

check:
	go vet ./...
	staticcheck ./...

elm: src/Main.elm
	elm make src/Main.elm --output=assets/main.js

sqlc: queries.sql schema.sql
	sqlc generate

build:
	go build

run: sqlc build
	./gostart -name startdev -db ./test.db
