create table owners
(
    id         integer primary key                not null,
    created_at datetime default current_timestamp not null,
    last_used  datetime default current_timestamp not null,
    name       text                               not null unique
);
create table watch_items
(
    id         integer primary key autoincrement,
    owner_id   INTEGER REFERENCES owners (id)     not null,
    created_at datetime default current_timestamp not null,
    name       text                               not null,
    repo       text                               not null,
    unique (name, repo)
);
create table pull_request_ignores
(
    id         integer primary key autoincrement,
    owner_id   INTEGER REFERENCES owners (id)     not null,
    created_at datetime default current_timestamp not null,
    number     integer                            not null,
    repo       text                               not null,
    unique (number, repo)
);
create table links
(
    id         integer primary key autoincrement,
    owner_id   INTEGER REFERENCES owners (id)     not null,
    created_at datetime default current_timestamp not null,
    url        text                               not null unique,
    name       text                               not null,
    clicked    integer  default 0                 not null,
    logo_url   text                               not null
);
create table pull_requests
(
    id          integer primary key autoincrement,
    owner_id    INTEGER REFERENCES owners (id)     not null,
    created_at  datetime default current_timestamp not null,
    number      integer                            not null unique,
    repo        text                               not null,
    description text                               not null,
    commitid    text
);
create table icons
(
    owner_id     INTEGER REFERENCES owners (id)            not null,
    link_id      integer primary key references links (id) not null,
    created_at   datetime default current_timestamp        not null,
    content_type text                                      not null,
    data         blob                                      not null
);
