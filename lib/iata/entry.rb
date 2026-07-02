# frozen_string_literal: true

require 'lutaml/model'
require_relative 'coordinates'

module Iata
  # A single IATA airport entry.
  #
  # Stores wire-level fields as `lutaml-model` attributes (so the bundled
  # JSON can be parsed round-trip) and exposes typed helpers (#coordinates,
  # #country_name) for ergonomic queries.
  class Entry < Lutaml::Model::Serializable
    attribute :code, :string
    attribute :name, :string
    attribute :wikidata_id, :string
    attribute :country_iso2, :string
    attribute :country_name, :string
    attribute :latitude, :float
    attribute :longitude, :float

    def coordinates
      return Coordinates.new(latitude: nil, longitude: nil) if latitude.nil? && longitude.nil?

      Coordinates.new(latitude: latitude, longitude: longitude)
    end

    def ==(other)
      other.is_a?(Entry) && code == other.code
    end

    def hash
      code&.hash || super
    end

    def eql?(other)
      self == other
    end

    def to_s
      "#{code} #{name}".strip
    end
  end
end
