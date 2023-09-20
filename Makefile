GOSRC!=find * -type f \( -name '*.go' -and -not -name '*_test.go' \)
GOSRC+=go.mod go.sum

gostart: $(GO_SRC) go.mod go.sum data assets/main.min.js
	go build -trimpath -o $@

assets/main.min.js: src/Main.elm
	elm make $< --optimize --output=assets/main.js
	uglifyjs assets/main.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output $@
	rm -f assets/main.js

data: queries.sql schema.sql
	sqlc generate
	touch data

.PHONY: check
check:
	go vet ./...
	staticcheck ./...

.PHONY: watch
watch:
	echo src/Main.elm | entr -r make assets/main.min.js

.PHONY: run
run: gostart
	./gostart -name startdev -db ./test.db -dev
