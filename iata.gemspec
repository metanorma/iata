# frozen_string_literal: true

require_relative 'lib/iata/version'

Gem::Specification.new do |spec|
  spec.name = 'iata'
  spec.version = Iata::VERSION
  spec.authors = ['Ribose Inc.']
  spec.email = ['open.source@ribose.com']

  spec.summary = 'IATA airport codes as a queryable Ruby registry'
  spec.description = <<~DESC
    Vendored, offline access to the IATA (International Air Transport
    Association) airport code list, sourced from Wikidata. Provides a
    model-driven Ruby registry for looking up airports by IATA code,
    country, or name.
  DESC
  spec.homepage = 'https://github.com/metanorma/iata'
  spec.license = 'BSD-2-Clause'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/metanorma/iata',
    'bug_tracker_uri' => 'https://github.com/metanorma/iata/issues',
    'rubygems_mfa_required' => 'true'
  }.freeze

  spec.files = Dir.chdir(__dir__) do
    Dir.glob('{lib}/**/*').reject { |f| File.directory?(f) }
  end.append('LICENSE').append('README.adoc').uniq
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'json', '~> 2.6'
  spec.add_dependency 'lutaml-model', '~> 0.8'
end
