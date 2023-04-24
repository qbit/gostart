package main

import (
	"sort"

	"suah.dev/gostart/data"
	"tailscale.com/tailcfg"
)

type Page struct {
	Title         string
	System        data.Owner
	PullRequests  []data.PullRequest
	Links         []data.Link
	Node          tailcfg.Node
	CurrentLimits *RateLimit
	Ignores       []data.PullRequestIgnore
	Watches       *WatchResults
}

func (p *Page) Sort() {
	sort.Slice(p.Links, func(i, j int) bool {
		return p.Links[i].Name < p.Links[j].Name
	})
	sort.Slice(p.PullRequests, func(i, j int) bool {
		return p.PullRequests[i].Number > p.PullRequests[j].Number
	})
}
