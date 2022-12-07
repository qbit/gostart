package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
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
		query: "is:open is:public archived:false repo:%s in:title %s", 
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

	defer func() {
		err := res.Body.Close()
		if err != nil {
			log.Fatal("can't close body: ", err)
		}
	}()

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

type WatchResults []WatchResult

func (w *WatchResults) forID(ownerID int64) *WatchResults {
	newResults := WatchResults{}
	for _, r := range *w {
		if r.OwnerID == ownerID {
			newResults = append(newResults, r)
		}
	}
	sort.Slice(newResults, func(i, j int) bool {
		return newResults[i].Name < newResults[j].Name
	})
	return &newResults
}

func (w WatchResults) GetLimits() *RateLimit {
	rl := &RateLimit{}
	sort.Slice(w, func(i, j int) bool {
		return w[i].Data.RateLimit.Remaining < w[j].Data.RateLimit.Remaining
	})
	if len(w) > 0 {
		rl = &w[0].Data.RateLimit
	}
	return rl
}

func UpdateWatches(ghToken string) (*WatchResults, error) {
	ctx := context.Background()
	w := WatchResults{}

	watches, err := app.queries.GetAllWatchItems(ctx)
	if err != nil {
		return nil, err
	}

	for _, watch := range watches {
		qd := GQLQuery{Query: fmt.Sprintf(graphQuery, watch.Repo, watch.Name)}
		wr, err := getData(qd, ghToken)
		if err != nil {
			return nil, err
		}

		wr.OwnerID = watch.OwnerID
		wr.Name = watch.Name
		wr.Repo = watch.Repo
		sort.Slice(wr.Data.Search.Edges, func(i, j int) bool {
			return wr.Data.Search.Edges[i].Node.CreatedAt.After(wr.Data.Search.Edges[j].Node.CreatedAt)
		})
		w = append(w, *wr)
	}

	sort.Slice(w, func(i, j int) bool {
		return w[i].Name < w[j].Name
	})

	return &w, nil
}

type WatchResult struct {
	Data    Data `json:"data,omitempty"`
	OwnerID int64
	Name    string
	Repo    string
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
