# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :iata do
  desc 'Fetch the IATA airport list from Wikidata (SPQRL)'
  task :fetch do
    require_relative 'lib/iata/data/fetcher'
    Iata::Data::Fetcher.call
  end
end
