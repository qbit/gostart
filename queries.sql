-- name: AddOwner :one
insert into owners (id, name, show_shared)
values (?, ?, ?) returning *;

-- name: GetOwner :one
select *
from owners
where id = ?;

-- name: GetAllWatchItems :many
select *
from watch_items;

-- name: GetAllWatchItemsByOwner :many
select *
from watch_items
where owner_id = ?;

-- name: AddWatchItem :one
insert into watch_items (owner_id, name, repo)
values (?, ?, ?) returning *;

-- name: DeleteWatchItem :exec
delete
from watch_items
where id = ?
  and owner_id = ?;

-- name: GetAllLinksForOwner :many
select *
from links
where owner_id = ?
   or shared = true;

-- name: GetAllLinks :many
select *
from links;

-- name: AddLink :one
insert into links (owner_id, url, name, logo_url, shared)
values (?, ?, ?, ?, ?) returning *;

-- name: GetLinkByID :one
select *
from links
where id = ?;

-- name: DeleteLink :exec
delete
from links
where id = ?
  and owner_id = ?;

-- name: GetAllIcons :many
select *
from icons
where owner_id = ?;

-- name: GetIconByLinkID :one
select *
from icons
where link_id = ?;

-- name: AddIcon :exec
insert
into icons (owner_id, link_id, content_type, data)
values (?, ?, ?, ?) on conflict(link_id) do
update set data = excluded.data, content_type = excluded.content_type;

-- name: GetAllPullRequests :many
select *
from pull_requests
where owner_id = ?;

-- name: AddPullRequest :one
insert into pull_requests (owner_id, number, repo, description, url)
values (?, ?, ?, ?, ?) returning *;

-- name: DeletePullRequest :exec
delete
from pull_requests
where id = ?
  and owner_id = ?;

-- name: GetAllPullRequestIgnores :many
select *
from pull_request_ignores
where owner_id = ?;

-- name: AddPullRequestIgnore :one
insert into pull_request_ignores (owner_id, number, repo)
values (?, ?, ?) returning *;
