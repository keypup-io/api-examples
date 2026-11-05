# Keypup API examples

Scripts that put your engineering data to work outside Keypup, through the
[Keypup API](https://www.keypup.io/api/). Each one is a complete, short
example to copy and adapt.

| Example | What it does |
|---|---|
| [Stale pull requests in Slack](slack-stale-pull-requests/) | Posts the pull requests nobody has touched for 3 days to a Slack channel, every morning |

They are written in Ruby (3.1 or later) with nothing else to install: an API
call is one HTTP request, easy to rewrite in your own language.

## Getting started

### 1. Create an API token

In Keypup, open **Settings > Account > API Tokens** and create a token with
the **Reporting API** scope. Copy it when it is shown: it is shown once.
See [Using the API](https://docs.keypup.io/en/articles/10260626-using-the-api)
for the scopes and the API Explorer.

### 2. Configure

```
cp .env.example .env
```

and fill in `KEYPUP_API_TOKEN` and `KEYPUP_COMPANY_ID`, your team's ID. You
find it in the variables of any query the API Explorer opens, as
`companyId`.

### 3. Run an example

Each example's README says what else it needs, and how to run it.

## Writing your own query

Every insight in Keypup is a query to the reporting API. In the insight
editor, **Open in API Explorer** opens the insight's query there, ready to run
and to copy into a script.

[`lib/keypup.rb`](lib/keypup.rb) sends a query and returns its rows. A query
names a dataset and lists metrics, dimensions and filters, each a formula, as
in the insight editor:

```ruby
Keypup.report(
  fact: 'ISSUES_PULL_REQUESTS',
  metrics: [{ label: 'merged', formula: 'COUNT()' }],
  dimensions: [{ label: 'week', formula: 'YEAR_WEEK(merged_at)', sort: 'ASC' }],
  filters: [{ formula: 'type == "pull_request" && merged_at >= NOW() - 90 * DAY()' }]
)
# => [{ "week" => "2026-W33", "merged" => 3 }, ...]
```

The datasets, their fields and the formula functions are in the API
Explorer's documentation, and in the
[functions dictionary](https://docs.keypup.io/en/collections/4252303-functions-dictionary).
