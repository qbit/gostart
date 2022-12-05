package main

import (
	"context"
	"log"
	"net/http"

	"suah.dev/gostart/data"
	"tailscale.com/client/tailscale"
	"tailscale.com/tailcfg"
	"tailscale.com/tsnet"
)

type App struct {
	tsServer      *tsnet.Server
	tsLocalClient *tailscale.LocalClient
	ctx           context.Context
	queries       *data.Queries
	watches       *WatchResults
}

func (a *App) getOwner(r *http.Request) (*tailcfg.Node, error) {
	who, err := a.tsLocalClient.WhoIs(r.Context(), r.RemoteAddr)
	if err != nil {
		return nil, err
	}

	ownerID := int64(who.Node.ID)

	ownerExists, err := a.queries.GetOwner(a.ctx, ownerID)
	if err != nil {
		log.Println("owner exists query failed: ", err)
	}

	if ownerExists.ID != ownerID {
		_, err = a.queries.AddOwner(a.ctx, data.AddOwnerParams{
			ID:   int64(who.Node.ID),
			Name: who.Node.ComputedName,
		})
		if err != nil {
			log.Fatal("adding owner failed: ", err)
		}
	}

	return who.Node, nil
}
