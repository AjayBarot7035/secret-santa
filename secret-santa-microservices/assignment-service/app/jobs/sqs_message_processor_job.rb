class SqsMessageProcessorJob < ApplicationJob
  queue_as :default

  def perform
    sqs_sns_service = SqsSnsService.new
    queue_url = ENV['SQS_QUEUE_ASSIGNMENT_SERVICE']
    topic_arn = ENV['SNS_TOPIC_ASSIGNMENTS_GENERATED']

    loop do
      begin
        # Receive message from SQS
        message = sqs_sns_service.receive_message(queue_url)

        if message
          process_message(message, sqs_sns_service, queue_url, topic_arn)
        end

        # Small delay to prevent tight loop
        sleep(1)
      rescue => e
        Rails.logger.error "Error in SQS message processor: #{e.message}"
        sleep(5) # Wait before retrying
      end
    end
  end

  private

  def process_message(message, sqs_sns_service, queue_url, topic_arn)
    # Parse the message body
    message_data = JSON.parse(message.body, symbolize_names: true)
    
    employees = message_data[:employees]
    previous_assignments = message_data[:previous_assignments] || []
    request_id = message_data[:request_id]

    # Generate assignments
    service = SecretSantaService.new
    result = service.generate_assignments(employees, previous_assignments)

    # Publish result to SNS
    sns_message = {
      success: result[:success],
      assignments: result[:assignments],
      request_id: request_id,
      timestamp: Time.current.iso8601,
      error: result[:error]
    }

    sqs_sns_service.publish_to_sns(topic_arn, sns_message)

    # Delete the message from SQS
    sqs_sns_service.delete_message(queue_url, message.receipt_handle)

    Rails.logger.info "Processed assignment request: #{request_id}"
  rescue => e
    Rails.logger.error "Error processing message: #{e.message}"
    
    # Publish error to SNS
    error_message = {
      success: false,
      error: e.message,
      request_id: message_data&.dig(:request_id),
      timestamp: Time.current.iso8601
    }

    sqs_sns_service.publish_to_sns(topic_arn, error_message)

    # Delete the message from SQS even if processing failed
    sqs_sns_service.delete_message(queue_url, message.receipt_handle)
  end
end
