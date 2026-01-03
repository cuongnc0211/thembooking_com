require 'database_cleaner/active_record'

RSpec.configure do |config|
  # Clean entire database before test suite starts
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  # Default strategy: transaction (fast)
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # System tests require truncation (run in separate server thread)
  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  # Start cleaning before each test
  config.before(:each) do
    DatabaseCleaner.start
  end

  # Clean up after each test
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
