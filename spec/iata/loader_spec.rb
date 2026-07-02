# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iata::Loader do
  let(:sample_path) { File.join(FIXTURES_DIR, 'airports_sample.json') }
  let(:sample_json) { File.read(sample_path) }

  describe '.load_file' do
    it 'reads a JSON file from disk' do
      entries = described_class.load_file(sample_path)
      expect(entries).to all(be_a(Iata::Entry))
      expect(entries.map(&:code).sort).to eq(%w[HKG JFK NRT PVG])
    end
  end

  describe '.load_json' do
    it 'parses JSON text into Entry instances' do
      entries = described_class.load_json(sample_json)
      expect(entries.size).to eq(4)
    end

    it 'returns empty array for empty JSON' do
      expect(described_class.load_json('{}')).to eq([])
    end
  end

  describe '.parse' do
    it 'builds Entry attributes from real Wikidata wire format' do
      parsed = JSON.parse(sample_json)
      entries = described_class.parse(parsed)
      pvg = entries.find { |e| e.code == 'PVG' }

      expect(pvg.name).to eq('Shanghai Pudong International Airport')
      expect(pvg.country_iso2).to eq('CN')
      expect(pvg.wikidata_id).to eq('Q86792')
      expect(pvg.latitude).to eq(31.1434)
      expect(pvg.longitude).to eq(121.8052)
    end

    it 'skips the _meta key' do
      parsed = JSON.parse(sample_json)
      entries = described_class.parse(parsed)
      expect(entries.map(&:code)).not_to include('_meta')
    end

    it 'returns empty array when given a non-Hash' do
      expect(described_class.parse('[]')).to eq([])
      expect(described_class.parse(nil)).to eq([])
    end
  end
end
