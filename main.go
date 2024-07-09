package main

import (
	"context"
	"crypto/tls"
	"database/sql"
	"embed"
	"flag"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/render"
	_ "github.com/mattn/go-sqlite3"
	"suah.dev/gostart/data"
	"tailscale.com/client/tailscale"
	"tailscale.com/tsnet"
	"tailscale.com/types/logger"
)

var (
	//go:embed schema.sql
	schema string

	//go:embed assets
	assets embed.FS
)

var app = &App{
	tsServer:      &tsnet.Server{},
	tsLocalClient: &tailscale.LocalClient{},
}

func main() {
	name := flag.String("name", "startpage", "name of service")
	key := flag.String("key", "", "path to file containing the api key")
	watchInterval := flag.Int64("refresh", 5, "number of minutes between watch refresh")
	dbFile := flag.String("db", ":memory:", "path to on-disk database file")
	tokenFile := flag.String("auth", "", "path to file containing GH auth token")
	dev := flag.Bool("dev", false, "develop mode, serve live files from ./assets")
	flag.Parse()

	db, err := sql.Open("sqlite3", fmt.Sprintf("%s?cache=shared&mode=rwc", *dbFile))
	if err != nil {
		log.Fatal("can't open database: ", err)
	}
	dbExists := false
	if *dbFile == ":memory:" {
		err := tmpDBPopulate(db)
		if err != nil {
			log.Fatal(err)
		}
		dbExists = true
	} else {
		if _, err := os.Stat(*dbFile); os.IsNotExist(err) {
			log.Println("Creating database..")
			ctx := context.Background()
			if _, err := db.ExecContext(ctx, schema); err != nil {
				log.Fatal("can't create database schema: ", err)
			}
		}
		dbExists = true
	}

	app.watches = &WatchResults{}
	app.queries = data.New(db)
	app.tsServer = &tsnet.Server{
		Hostname: *name,
	}

	if *dev {
		app.tsServer.Logf = logger.Discard
	}
	app.tsLocalClient, err = app.tsServer.LocalClient()
	if err != nil {
		log.Fatal("can't get ts local client: ", err)
	}

	/*
		go func() {
			time.Sleep(6 * time.Second)
			dbExists = true
		}()
	*/

	if *key != "" {
		keyData, err := os.ReadFile(*key)
		if err != nil {
			log.Fatal("can't read key file: ", err)
		}
		app.tsServer.AuthKey = string(keyData)
	}

	ln, err := app.tsServer.Listen("tcp", ":443")
	if err != nil {
		log.Fatal("can't listen: ", err)
	}

	defer func() {
		err := app.tsServer.Close()
		if err != nil {
			log.Fatal("can't close ts server: ", err)
		}
	}()

	router := chi.NewRouter()

	router.Use(middleware.Logger)
	router.Use(OwnerCtx)

	ghToken := os.Getenv("GH_AUTH_TOKEN")

	if *tokenFile != "" && ghToken == "" {
		tfBytes, err := os.ReadFile(*tokenFile)
		if err != nil {
			log.Fatal("can't read token file: ", err)
		}
		ghToken = string(tfBytes)
	}

	if ghToken == "" {
		log.Fatal("can't operate without GH_AUTH_TOKEN")
	}

	var liveServer http.Handler
	if *dev {
		liveServer = http.FileServer(http.Dir("./assets"))
	} else {
		embFS, _ := fs.Sub(assets, "assets")
		liveServer = http.FileServer(http.FS(embFS))
	}

	router.Mount("/", liveServer)
	router.Route("/pullrequests", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Get("/", pullrequestsGET)
		r.Delete("/{prID:[0-9]+}", pullrequestsDELETE)
		r.Post("/", pullrequestsPOST)
	})
	router.Route("/links", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Get("/", linksGET)
		r.Delete("/{linkID:[0-9]+}", linkDELETE)
		r.Get("/{linkID:[0-9]+}", linkGET)
		r.Post("/", linksPOST)
	})
	router.Route("/watches", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Get("/", watchitemGET)
		r.Delete("/{watchID:[0-9]+}", watchitemDELETE)
		r.Post("/", watchitemPOST)
	})
	router.Route("/prignores", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Post("/", prignorePOST)
		r.Get("/", prignoreGET)
		r.Delete("/{ignoreID:[0-9]+}", prignoreDELETE)
	})
	router.Route("/icons", func(r chi.Router) {
		r.Use(IconCacher)
		r.Get("/{linkID:[0-9]+}", iconGET)
	})
	router.Route("/update-icons", func(r chi.Router) {
		r.Get("/", func(w http.ResponseWriter, r *http.Request) {
			updateIcons()
			w.Header().Add("Content-type", "application/json")
			w.WriteHeader(200)
			w.Write([]byte(`{"update": true}`))
		})
	})

	go func() {
		for {
			if dbExists && ghToken != "" {
				var err error
				app.watches, err = UpdateWatches(ghToken)
				if err != nil {
					log.Println("can't update watches: ", err)
				}
				time.Sleep(time.Duration(*watchInterval) * time.Minute)
			} else {
				time.Sleep(3 * time.Second)
			}
		}

	}()

	go func() {
		if dbExists {
			for {
				updateIcons()
				time.Sleep(24 * time.Hour)
			}
		} else {
			time.Sleep(3 * time.Second)
		}
	}()

	hs := &http.Server{
		Handler: router,
		TLSConfig: &tls.Config{
			GetCertificate: app.tsLocalClient.GetCertificate,
		},
	}

	log.Panic(hs.ServeTLS(ln, "", ""))
}
