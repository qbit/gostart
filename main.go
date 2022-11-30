package main

import (
	"context"
	"crypto/tls"
	"database/sql"
	"embed"
	_ "embed"
	"flag"
	"github.com/go-chi/render"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	_ "modernc.org/sqlite"
	"suah.dev/gostart/data"
	"tailscale.com/client/tailscale"
	"tailscale.com/tsnet"
)

//go:embed schema.sql
var schema string

//go:embed templates
var templates embed.FS

//go:embed assets
var assets embed.FS

var app = &App{
	ctx:           context.Background(),
	tsServer:      &tsnet.Server{},
	tsLocalClient: &tailscale.LocalClient{},
}

func main() {
	name := flag.String("name", "startpage", "name of service")
	key := flag.String("key", "", "path to file containing the api key")
	dbFile := flag.String("db", "", "path to on-disk database file")
	tokenFile := flag.String("auth", "", "path to file containing GH auth token")
	flag.Parse()

	var db *sql.DB
	var err error
	if *dbFile == "" {
		db, err = sql.Open("sqlite", ":memory:")
		if err != nil {
			log.Fatal(err)
		}
	}

	app.queries = data.New(db)
	app.tsServer = &tsnet.Server{
		Hostname: *name,
	}
	app.tsLocalClient, err = app.tsServer.LocalClient()
	if err != nil {
		log.Fatal(err)
	}

	tmpDBPopulate(db)

	if *key != "" {
		keyData, err := os.ReadFile(*key)
		if err != nil {
			log.Fatal(err)
		}
		app.tsServer.AuthKey = string(keyData)
	}

	ln, err := app.tsServer.Listen("tcp", ":443")
	if err != nil {
		log.Fatal(err)
	}

	defer func() {
		err := app.tsServer.Close()
		if err != nil {
			log.Fatal(err)
		}
	}()

	fileServer := http.FileServer(http.FS(assets))
	r := chi.NewRouter()

	r.Use(middleware.Logger)
	r.Use(OwnerCtx)

	r.Mount("/assets", fileServer)
	r.Route("/", func(r chi.Router) {
		r.Get("/", index)
	})
	r.Route("/pullrequests", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Get("/", pullrequestsGET)
		r.Delete("/{prID:[0-9]+}", pullrequestsDELETE)
		r.Post("/", pullrequestsPOST)
	})
	r.Route("/links", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Get("/", linksGET)
		r.Post("/", linksPOST)
	})
	r.Route("/watches", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Get("/", watchitemGET)
	})

	app.watches = &WatchResults{}
	ghToken := os.Getenv("GH_AUTH_TOKEN")

	if *tokenFile != "" && ghToken == "" {
		tfBytes, err := os.ReadFile(*tokenFile)
		if err != nil {
			log.Fatal(err)
		}
		ghToken = string(tfBytes)
	}

	go func() {
		err := app.watches.Update(ghToken)
		if err != nil {
			log.Fatal(err)
		}
		time.Sleep(5 * time.Minute)
	}()

	hs := &http.Server{
		Handler: r,
		TLSConfig: &tls.Config{
			GetCertificate: app.tsLocalClient.GetCertificate,
		},
	}

	log.Panic(hs.ServeTLS(ln, "", ""))
}
