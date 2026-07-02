# frozen_string_literal: true

require 'forwardable'
require_relative 'loader'

module Iata
  # In-memory, lazily-indexed registry over a set of {Entry} instances.
  #
  # The default registry is loaded from the vendored dataset bundled with the
  # gem (see {.load_default}). Callers can also construct a registry from any
  # other source via {.from_entries} or {.load_file}.
  class Registry
    include Enumerable
    extend Forwardable

    attr_reader :entries

    def_delegators :@entries, :size, :count, :to_a, :empty?

    # Map of `#where` filter keys to the Entry attribute they read.
    # `name` is intentionally NOT in this map — it gets routed through
    # filter_name so Regexp / substring matching works (see apply_filter).
    SCALAR_FILTERS = {
      code: :code,
      country: :country_iso2,
      country_iso2: :country_iso2,
      wikidata_id: :wikidata_id
    }.freeze

    def initialize(entries = [])
      @entries = entries.freeze
    end

    def each(&)
      @entries.each(&)
    end

    class << self
      # Load the bundled dataset shipped inside the gem.
      # @return [Registry]
      def load_default
        from_entries(Loader.load_file(default_data_path))
      end

      # Load a specific JSON file from disk.
      # @param path [String]
      # @return [Registry]
      def load_file(path)
        from_entries(Loader.load_file(path))
      end

      # Build a registry from an existing list of entries.
      # @param entries [Array<Iata::Entry>]
      # @return [Registry]
      def from_entries(entries)
        new(entries)
      end

      private

      def default_data_path
        File.expand_path('data/airports.json', __dir__)
      end
    end

    # Exact-code lookup.
    # @param code [String] 3-letter IATA code (case-insensitive)
    # @return [Iata::Entry, nil]
    def find(code)
      return nil if code.nil?

      by_code[code.to_s.upcase]
    end

    alias [] find

    # Filter entries by one or more predicates. Scalar filters accept either
    # a single value or an array (any-of). `name` accepts a String
    # (case-insensitive equality) or a Regexp.
    #
    # @example
    #   registry.where(country: 'CN')
    #   registry.where(country: %w[CN HK], name: /international/i)
    #
    # @return [Array<Iata::Entry>]
    def where(filters)
      filters.reduce(entries) { |scope, (key, value)| apply_filter(scope, key, value) }
    end

    # All distinct country codes present in the registry, sorted.
    # @return [Array<String>]
    def countries
      entries.map(&:country_iso2).compact.uniq.sort
    end

    # Count of entries per country.
    # @return [Hash{String=>Integer}]
    def counts_by_country
      entries.each_with_object(Hash.new(0)) { |e, h| h[e.country_iso2] += 1 if e.country_iso2 }
    end

    private

    def by_code
      @by_code ||= entries.each_with_object({}) do |e, h|
        h[e.code.to_s.upcase] = e if e.code
      end
    end

    def apply_filter(scope, key, value)
      if SCALAR_FILTERS.key?(key)
        filter_scalar(scope, SCALAR_FILTERS.fetch(key), value)
      elsif key == :name
        filter_name(scope, value)
      else
        raise ArgumentError, "unknown filter: #{key.inspect}"
      end
    end

    def filter_scalar(scope, attr_name, value)
      candidates = Array(value).map { |v| v.to_s.upcase }
      scope.select do |e|
        attr_val = e.public_send(attr_name)
        attr_val && candidates.include?(attr_val.to_s.upcase)
      end
    end

    def filter_name(scope, value)
      scope.select { |e| e.name && name_matches?(e.name, value) }
    end

    def name_matches?(string, value)
      value.is_a?(Regexp) ? string.match?(value) : string.casecmp?(value.to_s)
    end
  end
end
