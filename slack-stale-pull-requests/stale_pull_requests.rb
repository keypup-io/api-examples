# frozen_string_literal: true

#
# Posts to Slack the pull requests nobody has touched for 3 days.
#
#   ruby slack-stale-pull-requests/stale_pull_requests.rb
#
# Run it every morning from cron or your CI's scheduler. See README.md.
#

require_relative '../lib/keypup'
Keypup.load_env

STALE_DAYS = 3

# The pull requests still open and not updated for STALE_DAYS, bots left out.
pull_requests = Keypup.report(
  fact: 'ISSUES_PULL_REQUESTS',
  dimensions: [
    { label: 'updated', formula: 'YEAR_MONTH_DAY(updated_at)', sort: 'ASC' },
    { label: 'title', formula: 'title' },
    { label: 'author', formula: 'author.username' },
    { label: 'repository', formula: 'project.name' },
    { label: 'url', formula: 'url' },
  ],
  filters: [
    { formula: 'type == "pull_request" && state == "OPEN"' },
    { formula: "updated_at <= NOW() - #{STALE_DAYS} * DAY()" },
    { formula: 'author.username !~ "^(dependabot|github-actions|renovate)"' },
  ]
)
if pull_requests.empty?
  puts 'No stale pull request today.'
  exit
end

# One line per pull request, linked to it.
lines = pull_requests.map do |pr|
  "<#{pr['url']}|#{pr['title']}>\n#{pr['repository']} - by #{pr['author']}, last updated #{pr['updated']}"
end

# Slack's Block Kit: a header, then the pull requests (50 blocks at most).
blocks = [
  { type: 'section', text: { type: 'mrkdwn', text: "*#{lines.size} pull requests waiting for #{STALE_DAYS} days or more*" } },
  *lines.first(48).map { |line| { type: 'section', text: { type: 'mrkdwn', text: line } } },
]
response = Net::HTTP.post(
  URI('https://slack.com/api/chat.postMessage'),
  # unfurl_links: false, or Slack previews every pull request under the list.
  { channel: ENV.fetch('SLACK_CHANNEL'), text: "#{lines.size} stale pull requests", blocks:, unfurl_links: false }.to_json,
  'Content-Type' => 'application/json; charset=utf-8',
  'Authorization' => "Bearer #{ENV.fetch('SLACK_BOT_TOKEN')}"
)
result = JSON.parse(response.body)
abort("Slack: #{result['error']}") unless result['ok']

puts "Posted #{lines.size} stale pull requests to #{ENV.fetch('SLACK_CHANNEL')}"
