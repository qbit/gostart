package main

import (
	"database/sql"
	"log"

	"suah.dev/gostart/data"
)

func tmpDBPopulate(db *sql.DB) {
	// create tables
	if _, err := db.ExecContext(app.ctx, schema); err != nil {
		log.Fatal(err)
	}

	ownerID := int64(57395170551826799)

	_, err := app.queries.AddOwner(app.ctx, data.AddOwnerParams{
		ID:   57395170551826799,
		Name: "europa.humpback-trout.ts.net.",
	})
	if err != nil {
		log.Fatal(err)
	}
	b, err := app.queries.AddLink(app.ctx, data.AddLinkParams{
		OwnerID: ownerID,
		Url:     "https://tapenet.org",
		Name:    "Tape::Net",
	})
	log.Println(b, err)

	_, err = app.queries.AddPullRequest(app.ctx, data.AddPullRequestParams{
		OwnerID:     ownerID,
		Number:      1234,
		Repo:        "NixOS/nixpkgs",
		Description: sql.NullString{String: "who knows"},
	})
	if err != nil {
		log.Fatal(err)
	}
	_, err = app.queries.AddWatchItem(app.ctx, data.AddWatchItemParams{
		Name:    "tailscale",
		Repo:    "NixOS/nixpkgs",
		OwnerID: ownerID,
	})
	if err != nil {
		log.Fatal(err)
	}

	_, err = app.queries.AddWatchItem(app.ctx, data.AddWatchItemParams{
		Name:    "openssh",
		OwnerID: ownerID,
		Repo:    "NixOS/nixpkgs",
	})
	if err != nil {
		log.Fatal(err)
	}
}
