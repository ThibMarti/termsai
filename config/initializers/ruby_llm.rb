RubyLLM.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.openai_api_base = ENV["OPENAI_API_BASE"] if ENV["OPENAI_API_BASE"].present?
end
