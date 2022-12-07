package main

import (
	"context"
	"crypto/tls"
	"database/sql"
	"embed"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/render"
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
	dbFile := flag.String("db", ":memory:", "path to on-disk database file")
	tokenFile := flag.String("auth", "", "path to file containing GH auth token")
	flag.Parse()

	db, err := sql.Open("sqlite", fmt.Sprintf("%s?cache=shared&mode=rwc", *dbFile))
	if err != nil {
		log.Fatal("can't open database: ", err)
	}

	app.queries = data.New(db)
	app.tsServer = &tsnet.Server{
		Hostname: *name,
	}
	app.tsLocalClient, err = app.tsServer.LocalClient()
	if err != nil {
		log.Fatal("can't get ts local client: ", err)
	}

	if *dbFile == ":memory:" {
		tmpDBPopulate(db)
	} else {
		if _, err := os.Stat(*dbFile); os.IsNotExist(err) {
			log.Println("Creating database..")
			if _, err := db.ExecContext(app.ctx, schema); err != nil {
				log.Fatal("can't create database schema: ", err)
			}
		}
	}

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
		r.Delete("/{linkID:[0-9]+}", linkDELETE)
		r.Post("/", linksPOST)
	})
	r.Route("/watches", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Get("/", watchitemGET)
		r.Delete("/{watchID:[0-9]+}", watchitemDELETE)
		r.Post("/", watchitemPOST)
	})
	r.Route("/prignores", func(r chi.Router) {
		r.Use(render.SetContentType(render.ContentTypeJSON))
		r.Post("/", prignorePOST)
	})
	r.Route("/icons", func(r chi.Router) {
		r.Use(IconCacher)
		r.Get("/{linkID:[0-9]+}", iconGET)
	})

	ghToken := os.Getenv("GH_AUTH_TOKEN")

	if *tokenFile != "" && ghToken == "" {
		tfBytes, err := os.ReadFile(*tokenFile)
		if err != nil {
			log.Fatal("can't read token file: ", err)
		}
		ghToken = string(tfBytes)
	}

	go func() {
		for {
			var err error
			app.watches, err = UpdateWatches(ghToken)
			if err != nil {
				log.Fatal("can't update watches: ", err)
			}
			time.Sleep(5 * time.Minute)
		}

	}()

	go func() {
		links, err := app.queries.GetAllLinks(app.ctx)
		if err != nil {
			log.Fatal("can't get links: ", err)
		}

		for _, link := range links {
			fmt.Println(link.LogoUrl)
			if link.LogoUrl == "" {
				continue
			}
			resp, err := http.Get(link.LogoUrl)
			if err != nil {
				log.Println(err)
				continue
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				log.Println(err)
				continue
			}
			err = resp.Body.Close()
			if err != nil {
				log.Println(err)
				continue
			}
			contentType := resp.Header.Get("Content-Type")

			err = app.queries.AddIcon(app.ctx, data.AddIconParams{
				OwnerID:     link.OwnerID,
				LinkID:      link.ID,
				ContentType: contentType,
				Data:        body,
			})
			if err != nil {
				log.Fatal("can't add icon: ", err)

			}
		}
		time.Sleep(24 * time.Hour)
	}()

	hs := &http.Server{
		Handler: r,
		TLSConfig: &tls.Config{
			GetCertificate: app.tsLocalClient.GetCertificate,
		},
	}

	log.Panic(hs.ServeTLS(ln, "", ""))
}
