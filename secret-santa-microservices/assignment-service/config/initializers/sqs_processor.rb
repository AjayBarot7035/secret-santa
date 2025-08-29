# Start SQS message processor in a separate thread when Rails starts
Rails.application.config.after_initialize do
  # Only start SQS processor in production or when explicitly enabled
  # In development, we'll use HTTP endpoints
  if Rails.env.production? || ENV['ENABLE_SQS_PROCESSOR'] == 'true'
    Thread.new do
      Rails.logger.info "Starting SQS message processor..."
      SqsMessageProcessorJob.perform_now
    rescue => e
      Rails.logger.error "Failed to start SQS message processor: #{e.message}"
    end
  else
    Rails.logger.info "SQS processor disabled - running in development mode with HTTP endpoints"
  end
end
