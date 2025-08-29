class SqsSnsService
  def initialize
    @sqs_client = Aws::SQS::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )

    @sns_client = Aws::SNS::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )
  end

  def receive_message(queue_url, max_messages: 1, wait_time_seconds: 20)
    response = @sqs_client.receive_message(
      queue_url: queue_url,
      max_number_of_messages: max_messages,
      wait_time_seconds: wait_time_seconds,
      message_attribute_names: ['All']
    )
    
    response.messages.first
  end

  def delete_message(queue_url, receipt_handle)
    @sqs_client.delete_message(
      queue_url: queue_url,
      receipt_handle: receipt_handle
    )
  end

  def publish_to_sns(topic_arn, message, attributes: {})
    default_attributes = {
      'service' => {
        string_value: 'assignment-service',
        data_type: 'String'
      },
      'timestamp' => {
        string_value: Time.current.iso8601,
        data_type: 'String'
      }
    }

    message_attributes = default_attributes.merge(attributes)

    @sns_client.publish(
      topic_arn: topic_arn,
      message: message.to_json,
      message_attributes: message_attributes
    )
  end

  def get_queue_url(queue_name)
    response = @sqs_client.get_queue_url(queue_name: queue_name)
    response.queue_url
  end

  def get_topic_arn(topic_name)
    response = @sns_client.list_topics
    topic = response.topics.find { |t| t.topic_arn.include?(topic_name) }
    topic&.topic_arn
  end
end
