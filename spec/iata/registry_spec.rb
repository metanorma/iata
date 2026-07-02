# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iata::Registry do
  let(:sample_path) { File.join(FIXTURES_DIR, 'airports_sample.json') }
  let(:registry) { described_class.load_file(sample_path) }

  describe '.load_default' do
    it 'raises a helpful error when the bundled data file is missing' do
      allow(described_class).to receive(:default_data_path)
        .and_return('/nonexistent/iata/data/airports.json')
      expect { described_class.load_default }
        .to raise_error(Errno::ENOENT, /airports\.json/)
    end
  end

  describe '.load_file' do
    it 'loads a registry from a JSON file' do
      expect(registry.size).to eq(4)
      expect(registry).not_to be_empty
    end
  end

  describe '.from_entries' do
    it 'builds a registry from a list of entries' do
      entries = [Iata::Entry.new(code: 'XXX')]
      registry = described_class.from_entries(entries)
      expect(registry.size).to eq(1)
      expect(registry.find('XXX')).to be_a(Iata::Entry)
    end
  end

  describe '#find' do
    it 'looks up entries by 3-letter IATA code' do
      entry = registry.find('PVG')
      expect(entry).to be_a(Iata::Entry)
      expect(entry.name).to eq('Shanghai Pudong International Airport')
    end

    it 'is case-insensitive' do
      expect(registry.find('pvg').code).to eq('PVG')
    end

    it 'returns nil for unknown codes' do
      expect(registry.find('ZZZ')).to be_nil
    end

    it 'returns nil for nil input' do
      expect(registry.find(nil)).to be_nil
    end
  end

  describe '#[] alias' do
    it 'aliases find' do
      expect(registry['PVG']).to eq(registry.find('PVG'))
    end
  end

  describe '#where' do
    it 'filters by country' do
      cn = registry.where(country: 'CN')
      expect(cn.size).to eq(1)
      expect(cn.first.code).to eq('PVG')
    end

    it 'accepts multiple values as any-of' do
      entries = registry.where(country: %w[CN HK])
      expect(entries.map(&:code).sort).to eq(%w[HKG PVG])
    end

    it 'filters by code' do
      entries = registry.where(code: 'JFK')
      expect(entries.map(&:code)).to eq(%w[JFK])
    end

    it 'filters by name with a Regexp' do
      entries = registry.where(name: /international/i)
      expect(entries.map(&:code).sort).to eq(%w[HKG JFK NRT PVG])
    end

    it 'filters by name with a case-insensitive string (exact match)' do
      entries = registry.where(name: 'Narita International Airport')
      expect(entries.map(&:code)).to eq(%w[NRT])
    end

    it 'combines filters' do
      entries = registry.where(country: 'CN', name: /pudong/i)
      expect(entries.map(&:code)).to eq(%w[PVG])
    end

    it 'raises ArgumentError for unknown filter keys' do
      expect { registry.where(unknown: 'x') }.to raise_error(ArgumentError)
    end
  end

  describe '#countries' do
    it 'lists all distinct country codes sorted' do
      expect(registry.countries).to eq(%w[CN HK JP US])
    end
  end

  describe '#counts_by_country' do
    it 'counts entries per country' do
      # add a duplicate so we see a count > 1
      extra = Iata::Entry.new(code: 'PEK', country_iso2: 'CN')
      r = described_class.from_entries(registry.entries + [extra])
      expect(r.counts_by_country).to eq('CN' => 2, 'HK' => 1, 'JP' => 1, 'US' => 1)
    end
  end

  describe '#each' do
    it 'iterates over entries' do
      codes = registry.map(&:code)
      expect(codes.sort).to eq(%w[HKG JFK NRT PVG])
    end
  end
end
