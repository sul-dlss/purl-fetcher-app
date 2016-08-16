[![Build Status](https://travis-ci.org/sul-dlss/purl-fetcher.png?branch=master)](https://travis-ci.org/sul-dlss/purl-fetcher) [![Coverage Status](https://coveralls.io/repos/github/sul-dlss/purl-fetcher/badge.svg?branch=master)](https://coveralls.io/github/sul-dlss/purl-fetcher?branch=master)


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
bundle exec rspec
```

## API Provided (as implemented)

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

##### Example Response
```json
{
  "changes": [
    {
      "druid": "druid:dd1111ee2222",
      "latest_change": "2014-01-01T00:00:00Z",
      "true_targets": [
        "SearchWorksPreview"
      ],
      "collections": [
        "druid:oo000oo0001"
      ]
    },
    {
      "druid": "druid:bb1111cc2222",
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

##### Example Response
```json
{
  "deletes": [
    {
      "druid": "druid:ee1111ff2222",
      "latest_change": "2014-01-01T00:00:00Z"
    },
    {
      "druid": "druid:ff1111gg2222",
      "latest_change": "2014-01-01T00:00:00Z"
    },
    {
      "druid": "druid:cc1111dd2222",
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
##### Parameters
Name | Located In | Description | Required | Schema | Default
---- | ---------- | ----------- | -------- | ------ | -------
`rows` | query | If `0` then only returns the count of collections | No | integer | |

##### Example Response
```json
[
  "druid:ff1111gg2222"
]
```

#### `/collections/:id`

`GET /collections/:id`

##### Summary
Collection information in PURL
##### Description
Not implemented
