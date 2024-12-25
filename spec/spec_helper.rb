require "bundler/setup"
require "mochitype"
require "action_view"
require "rails"
require "pry-byebug"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include our helper module in the test environment
  config.include Mochitype::ViewHelper
end
