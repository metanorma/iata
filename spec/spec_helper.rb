# frozen_string_literal: true

require 'iata'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end

  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.after do
    Iata.reset_registry!
  end
end

FIXTURES_DIR = File.expand_path('fixtures', __dir__)
