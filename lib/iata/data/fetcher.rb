# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'fileutils'

module Iata
  module Data
    # Downloads the IATA airport code list from Wikidata via SPARQL and
    # writes it to `lib/iata/data/airports.json` as a single JSON object
    # keyed by IATA code.
    #
    # Data source: Wikidata property P238 ("IATA airport code"). Each
    # result is an airport with its English label, ISO 3166-1 alpha-2
    # country code, and WGS-84 coordinates.
    module Fetcher
      SPARQL_ENDPOINT = 'https://query.wikidata.org/sparql'
      USER_AGENT = 'metanorma-iata-gem/0.1 (https://github.com/metanorma/iata)'
      DATA_DIR = File.expand_path(__dir__)
      OUTPUT_PATH = File.join(DATA_DIR, 'airports.json')

      QUERY = <<~SPARQL
        SELECT ?iata ?name ?country ?countryIso2 ?coord ?wdId WHERE {
          ?airport wdt:P238 ?iata .
          ?airport wdt:P17 ?country .
          ?airport rdfs:label ?name . FILTER(LANG(?name) = "en")
          OPTIONAL { ?country wdt:P297 ?countryIso2 . }
          OPTIONAL { ?airport wdt:P625 ?coord . }
          BIND(STRAFTER(STR(?airport), "/entity/") AS ?wdId)
        }
        ORDER BY ?iata
      SPARQL

      class << self
        # @return [String] the path written
        def call
          results = query
          data = transform(results)
          write(data, fetched_at: Time.now.utc.iso8601, result_count: results.size)
          warn "Fetched #{data.size} IATA airports from Wikidata (#{File.size(OUTPUT_PATH)} bytes)"
          OUTPUT_PATH
        end

        # @return [Array<Hash>] raw SPARQL bindings, each as a hash of {key: {value:, type:}}
        def query
          uri = URI(SPARQL_ENDPOINT)
          uri.query = URI.encode_www_form(
            query: QUERY,
            format: 'json'
          )

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')
          http.open_timeout = 30
          http.read_timeout = 180

          request = Net::HTTP::Get.new(uri.request_uri)
          request['User-Agent'] = USER_AGENT
          request['Accept'] = 'application/sparql-results+json'

          response = http.request(request)
          unless response.is_a?(Net::HTTPSuccess)
            raise "Wikidata SPARQL query failed: HTTP #{response.code} #{response.message}\n#{response.body[0..500]}"
          end

          JSON.parse(response.body, symbolize_names: true)[:results][:bindings]
        end

        # @param bindings [Array<Hash>] SPARQL result bindings
        # @return [Hash<String, Hash>] keyed by IATA code
        def transform(bindings)
          data = {}
          bindings.each do |row|
            code = row[:iata]&.dig(:value)
            next if code.nil?

            data[code] = build_entry(row)
          end
          data
        end

        def write(data, fetched_at:, result_count:)
          FileUtils.mkdir_p(DATA_DIR)
          payload = {
            '_meta' => {
              'fetched_at' => fetched_at,
              'source' => 'Wikidata (property P238)',
              'result_count' => result_count,
              'entry_count' => data.size
            }
          }.merge(data)
          File.write(OUTPUT_PATH, JSON.pretty_generate(payload))
        end

        private

        def build_entry(row)
          {
            'code' => row[:iata]&.dig(:value),
            'name' => row[:name]&.dig(:value),
            'wikidata_id' => row[:wdId]&.dig(:value),
            'country_iso2' => row[:countryIso2]&.dig(:value),
            'country_name' => extract_country_label(row[:country]),
            'latitude' => extract_lat(row[:coord]),
            'longitude' => extract_lon(row[:coord])
          }
        end

        def extract_country_label(country_binding)
          return nil unless country_binding

          uri = country_binding[:value].to_s
          # Use the entity's last URL segment as a placeholder; the human
          # name comes from the rdfs:label via SERVICE wikibase:label
          # which we don't include in the query. The dedicated
          # `unlocode-iso3166` gem is the proper way to resolve a full
          # country name; this is just a hint.
          uri.split('/').last
        end

        def extract_lat(coord_binding)
          return nil unless coord_binding

          point = coord_binding[:value].to_s
          match = point.match(/Point\(([-\d.]+)\s+([-\d.]+)/)
          match && match[2].to_f
        end

        def extract_lon(coord_binding)
          return nil unless coord_binding

          point = coord_binding[:value].to_s
          match = point.match(/Point\(([-\d.]+)\s+([-\d.]+)/)
          match && match[1].to_f
        end
      end
    end
  end
end
