all: sqlc elm build

check:
	go vet ./...
	staticcheck ./...

elm: src/Main.elm
	elm make src/Main.elm --optimize --output=assets/main.js
	uglifyjs assets/main.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output assets/main.min.js
	rm -f assets/main.js

sqlc: queries.sql schema.sql
	sqlc generate

build:
	go build

watch:
	echo src/Main.elm | entr -r elm make src/Main.elm --output=assets/main.js

run: sqlc build
	./gostart -name startdev -db ./test.db
