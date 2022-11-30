-- name: AddOwner :one
insert into owners (id, name)
values (?, ?) returning *;

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
insert into watch_items (owner_id, name, descr)
values (?, ?, ?) returning *;

-- name: DeleteWatchItem :exec
delete from watch_items where id = ? and owner_id = ?;

-- name: GetAllLinks :many
select *
from links
where owner_id = ?;

-- name: AddLink :one
insert into links (owner_id, url, name, logo_url)
values (?, ?, ?, ?) returning *;

-- name: DeleteLink :exec
delete from links where id = ? and owner_id = ?;

-- name: GetAllIcons :many
select *
from icons
where owner_id = ?;

-- name: AddIcon :one
insert into icons (owner_id, url, content_type, data)
values (?, ?, ?, ?) returning *;

-- name: GetAllPullRequests :many
select *
from pull_requests
where number not in (select number
                     from pull_request_ignores
                     where pull_request_ignores.owner_id = ?)
  and pull_requests.owner_id = ?;

-- name: AddPullRequest :one
insert into pull_requests (owner_id, number, repo, description)
values (?, ?, ?, ?) returning *;

-- name: DeletePullRequest :exec
delete from pull_requests where id = ? and owner_id = ?;

-- name: GetAllPullRequestIgnores :many
select *
from pull_request_ignores
where owner_id = ?;

-- name: AddPullRequestIgnore :one
insert into pull_request_ignores (owner_id, number, repo)
values (?, ?, ?) returning *;
