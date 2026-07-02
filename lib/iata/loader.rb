# frozen_string_literal: true

require 'json'
require_relative 'entry'

module Iata
  # Parses the bundled IATA airport JSON file into {Entry} instances.
  #
  # File format:
  #
  #   {
  #     "_meta": {
  #       "fetched_at": "2026-07-02T12:00:00Z",
  #       "source": "Wikidata (P238)",
  #       "count": 12345
  #     },
  #     "PVG": {
  #       "code": "PVG",
  #       "name": "Shanghai Pudong International Airport",
  #       "wikidata_id": "Q86792",
  #       "country_iso2": "CN",
  #       "country_name": "China",
  #       "latitude": 31.1434,
  #       "longitude": 121.8052
  #     },
  #     ...
  #   }
  class Loader
    class << self
      # @param path [String]
      # @return [Array<Iata::Entry>]
      def load_file(path)
        load_json(File.read(path))
      end

      # @param json [String]
      # @return [Array<Iata::Entry>]
      def load_json(json)
        parse(JSON.parse(json, symbolize_names: false))
      end

      # @param data [Hash]
      # @return [Array<Iata::Entry>]
      def parse(data)
        entries = data.is_a?(Hash) ? data.except('_meta') : {}
        entries.map { |_code, attrs| build_entry(attrs) }
      end

      private

      def build_entry(attrs)
        Entry.new(
          code: attrs['code'],
          name: attrs['name'],
          wikidata_id: attrs['wikidata_id'],
          country_iso2: attrs['country_iso2'],
          country_name: attrs['country_name'],
          latitude: attrs['latitude'],
          longitude: attrs['longitude']
        )
      end
    end
  end
end
