create table owners
(
    id         integer primary key not null,
    created_at datetime default current_timestamp,
    name       text                not null unique
);
create table watch_items
(
    id         integer primary key autoincrement,
    owner_id   INTEGER REFERENCES owners (id)     not null,
    created_at datetime default current_timestamp not null,
    name       text                               not null,
    repo       text                               not null,
    descr      text,
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
    logo_url   text
);
create table pull_requests
(
    id          integer primary key autoincrement,
    owner_id    INTEGER REFERENCES owners (id)     not null,
    created_at  datetime default current_timestamp not null,
    number      integer                            not null unique,
    repo        text                               not null,
    description text,
    commitid    text
);
create table icons
(
    id           integer primary key autoincrement,
    owner_id     INTEGER REFERENCES owners (id)     not null,
    created_at   datetime default current_timestamp not null,
    url          text                               not null unique,
    content_type text                               not null,
    data         blob                               not null
);
