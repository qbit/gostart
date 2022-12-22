package main

import (
	"database/sql"
	"log"

	"suah.dev/gostart/data"
)

func tmpDBPopulate(db *sql.DB) error {
	log.Println("CREATING TEMP DATABASE!")
	if _, err := db.ExecContext(app.ctx, schema); err != nil {
		return err
	}

	ownerID := int64(57395170551826799)

	_, err := app.queries.AddOwner(app.ctx, data.AddOwnerParams{
		ID:         57395170551826799,
		Name:       "europa.humpback-trout.ts.net.",
		ShowShared: true,
	})
	if err != nil {
		return err
	}
	_, err = app.queries.AddLink(app.ctx, data.AddLinkParams{
		OwnerID: ownerID,
		Url:     "https://tapenet.org",
		Name:    "Tape::Net",
		Shared:  true,
		LogoUrl: "https://git.tapenet.org/assets/img/logo.svg",
	})
	if err != nil {
		return err
	}

	_, err = app.queries.AddPullRequest(app.ctx, data.AddPullRequestParams{
		OwnerID: ownerID,
		Number:  1234,
		Repo:    "NixOS/nixpkgs",
	})
	if err != nil {
		return err
	}
	_, err = app.queries.AddWatchItem(app.ctx, data.AddWatchItemParams{
		Name:    "tailscale",
		Repo:    "NixOS/nixpkgs",
		OwnerID: ownerID,
	})
	if err != nil {
		return err
	}

	log.Println("Done setting up tmp DB")
	return nil
}
