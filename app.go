package main

import (
	"context"
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

	return who.Node, nil
}
