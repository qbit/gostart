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

	a, err := app.queries.AddOwner(app.ctx, data.AddOwnerParams{
		ID:   57395170551826799,
		Name: "europa.humpback-trout.ts.net.",
	})
	log.Println(a, err)

	b, err := app.queries.AddLink(app.ctx, data.AddLinkParams{
		OwnerID: ownerID,
		Url:     "https://tapenet.org",
		Name:    "Tape::Net",
	})
	log.Println(b, err)

	c, err := app.queries.AddPullRequest(app.ctx, data.AddPullRequestParams{
		OwnerID:     ownerID,
		Number:      1234,
		Repo:        "NixOS/nixpkgs",
		Description: sql.NullString{String: "who knows"},
	})
	log.Println(c, err)

	d, err := app.queries.AddWatchItem(app.ctx, data.AddWatchItemParams{
		Name:    "tailscale",
		OwnerID: ownerID,
	})
	log.Println(d, err)

	e, err := app.queries.AddWatchItem(app.ctx, data.AddWatchItemParams{
		Name:    "openssh",
		OwnerID: ownerID,
	})
	log.Println(e, err)
}
