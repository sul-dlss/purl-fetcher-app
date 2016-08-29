[![Build Status](https://travis-ci.org/sul-dlss/purl-fetcher.png?branch=master)](https://travis-ci.org/sul-dlss/purl-fetcher) [![Coverage Status](https://coveralls.io/repos/github/sul-dlss/purl-fetcher/badge.svg?branch=master)](https://coveralls.io/github/sul-dlss/purl-fetcher?branch=master) [![Dependency Status](https://gemnasium.com/sul-dlss/purl-fetcher.svg)](https://gemnasium.com/sul-dlss/purl-fetcher)


# purl-fetcher

A web service app that queries PURL to return info needed for indexing or other purposes.

## Setting up your environment

```bash

git clone https://github.com/sul-dlss/purl-fetcher.git

cd purl-fetcher

bundle install

rake db:migrate
rake db:migrate RAILS_ENV=test

```

## Running the application

```bash
rails server
```

## Logging

There are three log files:

* `indexing.log` - items that are being indexed (added or deleted)
* `[environment].log` - Rails logger
* `access.log` and `error.log` from Apache - traffic to the HTTP APIs

## Running tests

```bash
bundle exec rake
```

## API Provided (as implemented)

### Purl

#### `/purls`
`GET /purls`

#### Summary
Purl Index route
#### Description
The `/purls` endpoint provides information about public PURL documents.
##### Parameters
Name | Located In | Description | Required | Schema | Default
---- | ---------- | ----------- | -------- | ------ | -------
`object_type` | query | limit requests to a specific `object_type` | No | string | null
`page` | query | request a specific page of results | No | integer | 1
`per_page` | query | Limit the number of results per page | No | integer (1 - 10000) | 100
`version` | header | Version of the API request eg(`version=1`) | No | integer | 1

##### Example Response
```json
{
  "purls": [
    {
      "druid": "druid:ee1111ff2222",
      "published_at": "2013-01-01T00:00:00.000Z",
      "deleted_at": "2016-01-03T00:00:00.000Z",
      "object_type": "set",
      "catkey": "",
      "title": "Some test object number 4",
      "collections": [
        "druid:oo000oo0002"
      ],
      "true_targets": [
        "SearchWorksPreview"
      ]
    },
    {
      "druid": "druid:ff1111gg2222",
      "published_at": "2013-01-01T00:00:00.000Z",
      "deleted_at": "2014-01-01T00:00:00.000Z",
      "object_type": "collection",
      "catkey": "",
      "title": "Some test object number 5",
      "collections": [],
      "true_targets": [
        "SearchWorksPreview"
      ]
    }
  ],
  "pages": {
    "current_page": 1,
    "next_page": null,
    "prev_page": null,
    "total_pages": 1,
    "per_page": 100,
    "offset_value": 0,
    "first_page?": true,
    "last_page?": true
  }
}
```

#### `/purls/:druid`
`GET /purls/:druid`

##### Summary
Purl Document Show
##### Description
The `/purls/:druid` endpoint provides information about a specifc PURL document.
##### Parameters
Name | Located In | Description | Required | Schema | Default
---- | ---------- | ----------- | -------- | ------ | -------
`druid` | url | Druid of a specific PURL | Yes | string eg(`druid:cc1111dd2222`) | null
`version` | header | Version of the API request eg(`version=1`) | No | integer | 1

##### Example Response
```json
{
  "druid": "druid:cc1111dd2222",
  "published_at": "2016-01-01T00:00:00.000Z",
  "deleted_at": "2016-01-02T00:00:00.000Z",
  "object_type": "item",
  "catkey": "567",
  "title": "Some test object number 2",
  "collections": [
    "druid:oo000oo0002"
  ],
  "true_targets": [
    "SearchWorksPreview"
  ],
  "false_targets": [
    "SearchWorks"
  ]
}
```

### Docs

#### `/docs/changes`

`GET /docs/changes`

##### Summary
Purl Document Changes
##### Description
The `/docs/changes` endpoint provides information about public PURL documents that have been changed, their release tag information and also collection association.
##### Parameters
Name | Located In | Description | Required | Schema | Default
---- | ---------- | ----------- | -------- | ------ | -------
`first_modified` | query | Limit response by a beginning datetime | No | datetime in iso8601 | earliest possible date
`last_modified` | query | Limit response by an ending datetime| No | datetime in iso8601 | current time
`page` | query | request a specific page of results | No | integer | 1
`per_page` | query | Limit the number of results per page | No | integer (1 - 10000) | 100
`version` | header | Version of the API request eg(`version=1`) | No | integer | 1

##### Example Response
```json
{
  "changes": [
    {
      "druid": "druid:dd111ee2222",
      "latest_change": "2014-01-01T00:00:00Z",
      "true_targets": [
        "SearchWorksPreview"
      ],
      "collections": [
        "druid:oo000oo0001"
      ]
    },
    {
      "druid": "druid:bb111cc2222",
      "latest_change": "2015-01-01T00:00:00Z",
      "true_targets": [
        "SearchWorks",
        "Revs",
        "SearchWorksPreview"
      ],
      "collections": [
        "druid:oo000oo0001",
        "druid:oo000oo0002"
      ]
    },
    {
      "druid": "druid:aa111bb2222",
      "latest_change": "2016-06-06T00:00:00Z",
      "true_targets": [
        "SearchWorksPreview"
      ]
    },
  ],
  "pages": {
    "current_page": 1,
    "next_page": null,
    "prev_page": null,
    "total_pages": 1,
    "per_page": 100,
    "offset_value": 0,
    "first_page?": true,
    "last_page?": true
  }
}
```


#### `/docs/deletes`

`GET /docs/deletes`

##### Summary
Purl Document Deletes
##### Description
The `/docs/deletes` endpoint provides information about public PURL documents that have been deleted.
##### Parameters
Name | Located In | Description | Required | Schema | Default
---- | ---------- | ----------- | -------- | ------ | -------
`first_modified` | query | Limit response by a beginning datetime | No | datetime in iso8601 | earliest possible date
`last_modified` | query | Limit response by an ending datetime| No | datetime in iso8601 | current time
`page` | query | request a specific page of results | No | integer | 1
`per_page` | query | Limit the number of results per page | No | integer (1 - 10000) | 100
`version` | header | Version of the API request eg(`version=1`) | No | integer | 1

##### Example Response
```json
{
  "deletes": [
    {
      "druid": "druid:ee111ff2222",
      "latest_change": "2014-01-01T00:00:00Z"
    },
    {
      "druid": "druid:ff111gg2222",
      "latest_change": "2014-01-01T00:00:00Z"
    },
    {
      "druid": "druid:cc111dd2222",
      "latest_change": "2016-01-02T00:00:00Z"
    }
  ],
  "pages": {
    "current_page": 1,
    "next_page": null,
    "prev_page": null,
    "total_pages": 1,
    "per_page": 100,
    "offset_value": 0,
    "first_page?": true,
    "last_page?": true
  }
}
```

### Collections

#### `/collections`

`GET /collections`

##### Summary
Collections in PURL
##### Description
The `/collections` endpoint provides a druid list for collections in the public PURL space.
Note that this endpoint does NOT support pagination.
##### Parameters
Name | Located In | Description | Required | Schema | Default
---- | ---------- | ----------- | -------- | ------ | -------
`rows` | query | If `0` then only returns the count of collections | No | integer | |
`version` | header | Version of the API request eg(`version=1`) | No | integer | 1

##### Example Response
```json
[
  "druid:vj875jy1708",
  "druid:by138sy0351",
  "druid:zm034nd3311",
  "druid:mp394kd7603",
  "druid:ch172sb6466"
]
```

#### `/collections/:id`

`GET /collections/:id`

##### Summary
PURLs belonging to a given collection
##### Description
The `/collections/:id` endpoint provides a druid list for all PURLs that are members of the given collection.
Note that this endpoint does NOT support pagination.

##### Parameters
Name | Located In | Description | Required | Schema | Default
---- | ---------- | ----------- | -------- | ------ | -------
`id` | url | Druid of a specific collection | Yes | string eg(`druid:cc1111dd2222`) | null
`rows` | query | If `0` then only returns the count of PURLs in a collection | No | integer | |
`version` | header | Version of the API request eg(`version=1`) | No | integer | 1

##### Example Response
```json
[
  "druid:vh816yh7318",
  "druid:gd067wd7402",
  "druid:ys174nw6600",
  "druid:vf633bm1918"
]
```

## Administration

### Reporting

The API's internals use an [ActiveRecord data model](http://guides.rubyonrails.org/active_record_querying.html) to manage various information
about published PURLs. This model consists of `Purl`, `Collection`, and
`ReleaseTag` active records. See `app/models/` and `db/schema.rb` for details.

This approach provides administrators a couple ways to explore the data outside of the API.

#### Using Rails runner

With Rails' `runner`, you can query the database using ActiveRecord. For example, running the Ruby in `script/reports/summary.rb` using:

```bash
RAILS_ENV=environment bundle exec rails runner script/reports/summary.rb
```

produces output like this:

```
Summary report as of 2016-08-24 09:52:49 -0700 on purl-fetcher-dev.stanford.edu
PURLs: 193960
Deleted PURLs: 1
Published PURLs: 193959
Published PURLs in last week: 0
Released to SearchWorks: 5
```

#### Using SQL

With Rails' `dbconsole`, you can query the database using SQL. For example, running the SQL in `script/reports/summary.sql` using:

```bash
RAILS_ENV=environment bundle exec rails dbconsole -p < script/reports/summary.sql
```

produces output like this:

```
PURLs	193960
Deleted PURLs	1
Published PURLs	193959
Published this year	9
Released to SearchWorks	5
```
