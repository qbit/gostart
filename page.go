package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sort"
	"time"

	"suah.dev/gostart/data"
	"tailscale.com/tailcfg"
)

const gqEndPoint = "https://api.github.com/graphql"

const graphQuery = `
{      
	search(
		query: "is:open is:public archived:false repo:nixos/nixpkgs in:title %s", 
		type: ISSUE, 
		first: 20
	) {
        issueCount
        edges {
          node {
            ... on Issue {
              number
              title
              url
              repository {
                nameWithOwner
              }
              createdAt
            }
            ... on PullRequest {
              number
              title
              repository {
                nameWithOwner
              }
              createdAt
              url
            }
          }
        }
      }
      rateLimit {
        remaining
        resetAt
      }
    }
`

type GQLQuery struct {
	Query string `json:"query"`
}

func getData(q GQLQuery, token string) (*WatchResult, error) {
	var req *http.Request
	var err error
	var re = &WatchResult{}

	client := &http.Client{}
	buf := new(bytes.Buffer)
	if err := json.NewEncoder(buf).Encode(q); err != nil {
		return nil, err
	}

	req, err = http.NewRequest("POST", gqEndPoint, buf)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", fmt.Sprintf("bearer %s", token))

	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}

	defer res.Body.Close()

	if err = json.NewDecoder(res.Body).Decode(re); err != nil {
		return nil, err
	}

	return re, nil
}

type Page struct {
	Title         string
	PullRequests  []data.PullRequest
	Links         []data.Link
	Node          tailcfg.Node
	Watches       WatchResults
	CurrentLimits *RateLimit
}

func (p *Page) Sort() {
	sort.Slice(p.Links, func(i, j int) bool {
		return p.Links[i].Name > p.Links[j].Name
	})
	sort.Slice(p.PullRequests, func(i, j int) bool {
		return p.PullRequests[i].Number > p.PullRequests[j].Number
	})
	sort.Slice(p.Watches, func(i, j int) bool {
		return p.Watches[i].Name < p.Watches[j].Name
	})
	for _, w := range p.Watches {
		sort.Slice(w.Data.Search.Edges, func(i, j int) bool {
			return w.Data.Search.Edges[i].Node.CreatedAt.After(w.Data.Search.Edges[j].Node.CreatedAt)
		})
	}
}

type WatchResults []WatchResult

func (w WatchResults) forID(ownerID int64) WatchResults {
	newResults := WatchResults{}
	fmt.Printf("%v\n", w)
	for _, r := range w {
		if r.OwnerID == ownerID {
			newResults = append(newResults, r)
		}
	}

	return newResults
}

func (w WatchResults) GetLimits() *RateLimit {
	sort.Slice(w, func(i, j int) bool {
		return w[i].Data.RateLimit.Remaining < w[j].Data.RateLimit.Remaining
	})
	return &w[0].Data.RateLimit
}

func (w *WatchResults) Update(ghToken string) error {
	ctx := context.Background()
	watches, err := app.queries.GetAllWatchItems(ctx)
	if err != nil {
		return err
	}

	for _, watch := range watches {
		qd := GQLQuery{Query: fmt.Sprintf(graphQuery, watch.Name)}
		wr, err := getData(qd, ghToken)
		if err != nil {
			return err
		}

		// TODO: cross ref the list of ignores and prune the wr accordingly
		wr.OwnerID = watch.OwnerID
		wr.Name = watch.Name
		*w = append(*w, *wr)
	}

	return nil
}

type WatchResult struct {
	Data    Data `json:"data,omitempty"`
	OwnerID int64
	Name    string
}
type Repository struct {
	NameWithOwner string `json:"nameWithOwner,omitempty"`
}
type Node struct {
	Number     int        `json:"number,omitempty"`
	Title      string     `json:"title,omitempty"`
	Repository Repository `json:"repository,omitempty"`
	CreatedAt  time.Time  `json:"createdAt,omitempty"`
	URL        string     `json:"url,omitempty"`
}
type Edges struct {
	Node Node `json:"node,omitempty"`
}
type Search struct {
	IssueCount int     `json:"issueCount,omitempty"`
	Edges      []Edges `json:"edges,omitempty"`
}
type RateLimit struct {
	Remaining int       `json:"remaining,omitempty"`
	ResetAt   time.Time `json:"resetAt,omitempty"`
}
type Data struct {
	Search    Search    `json:"search,omitempty"`
	RateLimit RateLimit `json:"rateLimit,omitempty"`
}
