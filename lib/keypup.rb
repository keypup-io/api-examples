# frozen_string_literal: true

#
# The few lines every example needs to call the Keypup reporting API, with no
# gem to install: Ruby's own HTTP client and a reader for the .env file.
#

require 'json'
require 'net/http'

module Keypup
  REPORTING_API = URI('https://viz.keypup.io/graphql')

  # One query, written as the API Explorer writes it: the dataset, then
  # metrics, dimensions and filters, each a formula.
  QUERY = <<~GRAPHQL
    query($companyId: String!, $fact: FactEnum!, $metrics: [MetricInput!], $dimensions: [DimensionInput!],
          $filters: [FilterInput!], $limit: Int, $offset: Int) {
      report(queries: [{ target: "rows", companyScopes: [$companyId], fact: $fact, metrics: $metrics,
                         dimensions: $dimensions, filters: $filters, limit: $limit, offset: $offset }]) {
        results
        errors { message }
      }
    }
  GRAPHQL

  module_function

  # Reads KEY=value lines from the .env file at the root of the repository
  # into ENV, without overriding what is already set.
  def load_env(file = File.expand_path('../.env', __dir__))
    return unless File.exist?(file)

    File.foreach(file) do |line|
      key, value = line.strip.split('=', 2)
      next if key.nil? || key.start_with?('#') || value.nil?

      ENV[key] ||= value.delete_prefix('"').delete_suffix('"')
    end
  end

  # Runs a report and returns its rows, each a hash keyed by the labels of
  # the query's metrics and dimensions.
  def report(fact:, metrics: [], dimensions: [], filters: [], limit: 1000, offset: 0)
    variables = { companyId: ENV.fetch('KEYPUP_COMPANY_ID'), fact:, metrics:, dimensions:, filters:, limit:, offset: }
    response = Net::HTTP.post(REPORTING_API, { query: QUERY, variables: }.to_json,
                              'Content-Type' => 'application/json',
                              'Authorization' => "Bearer #{ENV.fetch('KEYPUP_API_TOKEN')}")
    body = JSON.parse(response.body)
    errors = [*body['errors'], *body.dig('data', 'report', 'errors')].compact
    raise "Keypup: #{errors.map { |e| e['message'] }.join(', ')}" if errors.any? || !response.is_a?(Net::HTTPSuccess)

    body.dig('data', 'report', 'results', 'rows')
  end
end
