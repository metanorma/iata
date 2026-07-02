# frozen_string_literal: true

module Iata
  # Geographic coordinates (WGS-84) for an IATA airport entry.
  class Coordinates
    attr_reader :latitude, :longitude

    def initialize(latitude: nil, longitude: nil)
      @latitude = latitude&.to_f
      @longitude = longitude&.to_f
    end

    def to_a
      [latitude, longitude].compact
    end

    def ==(other)
      other.is_a?(Coordinates) &&
        latitude == other.latitude &&
        longitude == other.longitude
    end

    def to_s
      return '' if latitude.nil? || longitude.nil?

      format('%<lat>.4f %<lon>.4f', lat: latitude, lon: longitude)
    end

    # Great-circle distance in kilometres to another Coordinates, using
    # the haversine formula. Returns nil if either side lacks coordinates.
    def distance_to(other)
      return nil if latitude.nil? || longitude.nil? ||
                    other.latitude.nil? || other.longitude.nil?

      earth_radius_km = 6371.0
      d_lat = (other.latitude - latitude) * (Math::PI / 180)
      d_lon = (other.longitude - longitude) * (Math::PI / 180)
      a = (Math.sin(d_lat / 2)**2) +
          (Math.cos(latitude * (Math::PI / 180)) *
           Math.cos(other.latitude * (Math::PI / 180)) *
           (Math.sin(d_lon / 2)**2))
      2 * earth_radius_km * Math.asin(Math.sqrt(a))
    end
  end
end
