# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iata::Entry do
  let(:entry) do
    described_class.new(
      code: 'PVG',
      name: 'Shanghai Pudong International Airport',
      wikidata_id: 'Q86792',
      country_iso2: 'CN',
      country_name: 'China',
      latitude: 31.1434,
      longitude: 121.8052
    )
  end

  describe 'attribute accessors' do
    it 'exposes code, name, wikidata_id, country, lat/lon' do
      expect(entry.code).to eq('PVG')
      expect(entry.name).to eq('Shanghai Pudong International Airport')
      expect(entry.wikidata_id).to eq('Q86792')
      expect(entry.country_iso2).to eq('CN')
      expect(entry.country_name).to eq('China')
      expect(entry.latitude).to eq(31.1434)
      expect(entry.longitude).to eq(121.8052)
    end
  end

  describe '#coordinates' do
    it 'wraps lat/lon in a Coordinates value type' do
      coords = entry.coordinates
      expect(coords).to be_a(Iata::Coordinates)
      expect(coords.latitude).to eq(31.1434)
      expect(coords.longitude).to eq(121.8052)
    end

    it 'returns nil lat/lon when both attributes are nil' do
      empty = described_class.new(code: 'XXX')
      expect(empty.coordinates.latitude).to be_nil
      expect(empty.coordinates.longitude).to be_nil
    end
  end

  describe 'equality' do
    it 'compares entries by IATA code' do
      same = described_class.new(code: 'PVG', name: 'Different')
      other = described_class.new(code: 'HKG')
      expect(entry).to eq(same)
      expect(entry).not_to eq(other)
      expect(entry.eql?(same)).to be true
    end
  end

  describe '#to_s' do
    it 'renders code + name' do
      expect(entry.to_s).to eq('PVG Shanghai Pudong International Airport')
    end

    it 'renders code alone when name is nil' do
      expect(described_class.new(code: 'XXX').to_s).to eq('XXX')
    end
  end
end
