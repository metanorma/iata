# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iata do
  after { described_class.reset_registry! }

  describe '.registry' do
    it 'is memoized' do
      expect(described_class.registry).to equal(described_class.registry)
    end

    it 'can be reset' do
      first = described_class.registry
      described_class.reset_registry!
      expect(described_class.registry).not_to equal(first)
    end
  end

  describe 'VERSION' do
    it 'exposes a version string' do
      expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+/)
    end
  end

  describe 'delegated query shortcuts' do
    before do
      registry = Iata::Registry.from_entries([
                                               Iata::Entry.new(code: 'PVG', country_iso2: 'CN',
                                                               name: 'Shanghai Pudong'),
                                               Iata::Entry.new(code: 'JFK', country_iso2: 'US', name: 'New York JFK')
                                             ])
      allow(described_class).to receive(:registry).and_return(registry)
    end

    it 'delegates find to the registry' do
      expect(described_class.find('PVG').name).to eq('Shanghai Pudong')
    end

    it 'delegates where to the registry' do
      expect(described_class.where(country: 'CN').map(&:code)).to eq(%w[PVG])
    end

    it 'delegates countries to the registry' do
      expect(described_class.countries).to eq(%w[CN US])
    end

    it 'delegates count to the registry' do
      expect(described_class.count).to eq(2)
    end
  end
end
