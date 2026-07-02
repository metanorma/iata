# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iata::Coordinates do
  describe '.new' do
    it 'coerces latitude/longitude to Float' do
      c = described_class.new(latitude: '31.1434', longitude: '121.8052')
      expect(c.latitude).to eq(31.1434)
      expect(c.longitude).to eq(121.8052)
    end

    it 'accepts nil' do
      c = described_class.new
      expect(c.latitude).to be_nil
      expect(c.longitude).to be_nil
    end
  end

  describe '#distance_to' do
    it 'computes great-circle distance between two points' do
      shanghai = described_class.new(latitude: 31.1434, longitude: 121.8052)
      hong_kong = described_class.new(latitude: 22.3089, longitude: 113.9145)
      distance = shanghai.distance_to(hong_kong)
      expect(distance).to be_within(50).of(1255) # ~1255km SHA↔HKG
    end

    it 'returns 0 for identical coordinates' do
      p = described_class.new(latitude: 1.0, longitude: 2.0)
      expect(p.distance_to(p)).to be_within(0.001).of(0.0)
    end

    it 'returns nil when either side has nil coordinates' do
      a = described_class.new(latitude: 1.0, longitude: 2.0)
      b = described_class.new
      expect(a.distance_to(b)).to be_nil
      expect(b.distance_to(a)).to be_nil
    end
  end

  describe '#to_s' do
    it 'formats to 4 decimal places' do
      c = described_class.new(latitude: 31.1434, longitude: 121.8052)
      expect(c.to_s).to eq('31.1434 121.8052')
    end

    it 'returns empty string when coords are nil' do
      expect(described_class.new.to_s).to eq('')
    end
  end

  describe '#==' do
    it 'compares by lat/lon' do
      a = described_class.new(latitude: 1.0, longitude: 2.0)
      b = described_class.new(latitude: 1.0, longitude: 2.0)
      c = described_class.new(latitude: 3.0, longitude: 4.0)
      expect(a).to eq(b)
      expect(a).not_to eq(c)
    end
  end
end
