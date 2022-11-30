// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.16.0

package data

import (
	"database/sql"
	"time"
)

type Icon struct {
	ID          int64     `json:"id"`
	OwnerID     int64     `json:"owner_id"`
	CreatedAt   time.Time `json:"created_at"`
	Url         string    `json:"url"`
	ContentType string    `json:"content_type"`
	Data        []byte    `json:"data"`
}

type Link struct {
	ID        int64          `json:"id"`
	OwnerID   int64          `json:"owner_id"`
	CreatedAt time.Time      `json:"created_at"`
	Url       string         `json:"url"`
	Name      string         `json:"name"`
	LogoUrl   sql.NullString `json:"logo_url"`
}

type Owner struct {
	ID        int64        `json:"id"`
	CreatedAt sql.NullTime `json:"created_at"`
	Name      string       `json:"name"`
}

type PullRequest struct {
	ID          int64          `json:"id"`
	OwnerID     int64          `json:"owner_id"`
	CreatedAt   time.Time      `json:"created_at"`
	Number      int64          `json:"number"`
	Repo        string         `json:"repo"`
	Description sql.NullString `json:"description"`
	Commitid    sql.NullString `json:"commitid"`
}

type PullRequestIgnore struct {
	ID        int64     `json:"id"`
	OwnerID   int64     `json:"owner_id"`
	CreatedAt time.Time `json:"created_at"`
	Number    int64     `json:"number"`
	Repo      string    `json:"repo"`
}

type WatchItem struct {
	ID        int64          `json:"id"`
	OwnerID   int64          `json:"owner_id"`
	CreatedAt time.Time      `json:"created_at"`
	Name      string         `json:"name"`
	Descr     sql.NullString `json:"descr"`
}
