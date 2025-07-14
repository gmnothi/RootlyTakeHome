# Configure Redis for Rails cache store and Sidekiq
require 'redis'

# Configure Sidekiq to use Redis
Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/1' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/1' }
end

# Ensure Rails cache store is using Redis
Rails.application.config.cache_store = :redis_cache_store, { 
  url: 'redis://localhost:6379/1',
  namespace: 'rootly_incident_assistant'
} 