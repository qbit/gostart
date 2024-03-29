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

type WatchResults []WatchResult

func includeWatch(repo string, number int, ignoreList []data.PullRequestIgnore) bool {
	for _, pri := range ignoreList {
		if pri.Repo == repo && pri.Number == int64(number) {
			return false
		}
	}
	return true
}

func (w *WatchResults) forID(ownerID int64) *WatchResults {
	newResults := WatchResults{}
	tmpResults := WatchResults{}
	ctx := context.Background()
	ignores, _ := app.queries.GetAllPullRequestIgnores(ctx, ownerID)

	for _, r := range *w {
		if r.OwnerID == ownerID {
			if r.Results == nil {
				r.Results = make([]Node, 0)
			}

			tmpResults = append(tmpResults, r)
		}
	}
	sort.Slice(newResults, func(i, j int) bool {
		return newResults[i].Name < newResults[j].Name
	})

	for _, r := range tmpResults {
		tmpResultList := []Node{}
		for _, entry := range r.Results {
			if includeWatch(entry.Repository.NameWithOwner, entry.Number, ignores) {
				tmpResultList = append(tmpResultList, entry)
			}
		}
		r.Results = tmpResultList
		r.ResultCount = len(tmpResultList)
		newResults = append(newResults, r)

	}

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
	if ghToken == "" {
		return nil, fmt.Errorf("invalid github token")
	}
	ctx := context.Background()
	w := WatchResults{}

	watches, err := app.queries.GetAllWatchItems(ctx)
	if err != nil {
		return nil, err
	}

	for _, watch := range watches {
		qd := GQLQuery{Query: fmt.Sprintf(graphQuery, watch.Repo, watch.Name)}
		wr, err := getWatchData(qd, ghToken)
		if err != nil {
			return nil, err
		}

		wr.OwnerID = watch.OwnerID
		wr.Name = watch.Name
		wr.Repo = watch.Repo
		wr.ID = watch.ID
		for _, dr := range wr.Data.Search.Edges {
			wr.Results = append(wr.Results, dr.Node)
		}
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
	ID          int64  `json:"id"`
	Data        Data   `json:"data"`
	OwnerID     int64  `json:"owner_id"`
	Name        string `json:"name"`
	Repo        string `json:"repo"`
	Results     []Node `json:"results"`
	ResultCount int    `json:"result_count"`
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

func getWatchData(q GQLQuery, token string) (*WatchResult, error) {
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
