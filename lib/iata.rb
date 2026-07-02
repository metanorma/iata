# frozen_string_literal: true

require 'forwardable'
require 'lutaml/model'
require 'json'

require_relative 'iata/version'

# Vendored IATA airport code list as a queryable Ruby registry.
#
# The data is sourced from Wikidata (property P238, "IATA airport code") and
# ships inside the gem as a small JSON file so the registry works offline.
# All entries are loaded lazily on first call to {.registry}.
module Iata
  extend SingleForwardable

  class << self
    # @return [Iata::Registry] the process-wide registry, loaded lazily
    def registry
      @registry ||= Registry.load_default
    end

    # Reset the process-wide registry. Used by specs to swap fixtures.
    def reset_registry!
      @registry = nil
    end

    # The Wikidata query timestamp bundled with this gem version
    # (UTC ISO8601). nil if the data file lacks this metadata.
    # @return [String, nil]
    def source_timestamp
      @source_timestamp ||= registry.entries.first&.source_timestamp
    end
  end

  def_delegators :registry, :find, :where, :each, :size, :count, :countries, :counts_by_country

  autoload :Coordinates, 'iata/coordinates'
  autoload :Entry, 'iata/entry'
  autoload :Loader, 'iata/loader'
  autoload :Registry, 'iata/registry'
  autoload :Data, 'iata/data'
end
