package main

import (
	"log"
	"net/http"

	"suah.dev/gostart/data"
	"tailscale.com/client/local"
	"tailscale.com/tailcfg"
	"tailscale.com/tsnet"
)

type App struct {
	tsServer      *tsnet.Server
	tsLocalClient *local.Client
	queries       *data.Queries
	watches       *WatchResults
}

func (a *App) getOwner(r *http.Request) (*tailcfg.Node, error) {
	ctx := r.Context()
	who, err := a.tsLocalClient.WhoIs(r.Context(), r.RemoteAddr)
	if err != nil {
		return nil, err
	}

	ownerID := int64(who.Node.ID)

	ownerExists, err := a.queries.GetOwner(ctx, ownerID)
	if err != nil || ownerExists.ID != ownerID {
		_, err = a.queries.AddOwner(ctx, data.AddOwnerParams{
			ID:         int64(who.Node.ID),
			Name:       who.Node.ComputedName,
			ShowShared: false,
		})
		if err != nil {
			log.Printf("adding owner failed (ownerID: %#v) (ownerExists: %#v): %s", ownerID, ownerExists, err)
			return nil, err
		}
	}

	return who.Node, nil
}

func (a *App) removeWatch(id int) {
	newWatches := WatchResults{}
	for _, w := range *a.watches {
		if w.ID != int64(id) {
			newWatches = append(newWatches, w)
		}
	}
	a.watches = &newWatches
}
