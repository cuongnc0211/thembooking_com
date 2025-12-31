Honeybadger.configure do |config|
  config.revision = ENV["HONEYBADGER_REVISION"] || ENV["KAMAL_VERSION"]
end
