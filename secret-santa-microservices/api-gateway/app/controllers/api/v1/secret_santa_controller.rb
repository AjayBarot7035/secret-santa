class Api::V1::SecretSantaController < ApplicationController
  def generate_assignments
    csv_data = params[:csv_data]
    previous_assignments = params[:previous_assignments] || []

    # Check if we're in development mode
    if development_mode?
      # Development mode: Direct HTTP calls
      result = process_assignments_directly(csv_data, previous_assignments)
      render json: result
    else
      # Production mode: SNS publishing
      begin
        publish_to_sns(
          topic_arn: sns_topic_employee_data_raw,
          message: {
            csv_data: csv_data,
            previous_assignments: previous_assignments,
            request_id: SecureRandom.uuid,
            timestamp: Time.current.iso8601
          }.to_json
        )
        
        render json: { 
          success: true, 
          message: 'Assignment request submitted successfully',
          request_id: SecureRandom.uuid
        }
      rescue Aws::SNS::Errors::ServiceError => e
        render json: { success: false, error: "SNS publishing failed: #{e.message}" }, status: :service_unavailable
      rescue StandardError => e
        render json: { success: false, error: "Internal server error: #{e.message}" }, status: :internal_server_error
      end
    end
  end

  def health
    render json: { status: 'healthy', service: 'Secret Santa API Gateway' }
  end

  def check_assignment_status
    request_id = params[:request_id]
    
    # Check SQS queue for completed assignments
    begin
      message = receive_from_sqs(
        queue_url: sqs_queue_assignments_completed,
        max_messages: 1,
        wait_time_seconds: 5
      )
      
      if message
        assignment_data = JSON.parse(message.body, symbolize_names: true)
        if assignment_data[:request_id] == request_id
          # Delete the message from queue
          delete_from_sqs(queue_url: sqs_queue_assignments_completed, receipt_handle: message.receipt_handle)
          
          render json: { 
            success: true, 
            assignments: assignment_data[:assignments],
            status: 'completed'
          }
        else
          render json: { success: false, error: 'Assignment not found' }, status: :not_found
        end
      else
        render json: { success: false, error: 'Assignment still processing' }, status: :accepted
      end
    rescue StandardError => e
      render json: { success: false, error: "Error checking status: #{e.message}" }, status: :internal_server_error
    end
  end

  private

  def sns_client
    @sns_client ||= Aws::SNS::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )
  end

  def sqs_client
    @sqs_client ||= Aws::SQS::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )
  end

  def publish_to_sns(topic_arn:, message:)
    sns_client.publish(
      topic_arn: topic_arn,
      message: message,
      message_attributes: {
        'service' => {
          string_value: 'api-gateway',
          data_type: 'String'
        },
        'timestamp' => {
          string_value: Time.current.iso8601,
          data_type: 'String'
        }
      }
    )
  end

  def receive_from_sqs(queue_url:, max_messages: 1, wait_time_seconds: 20)
    response = sqs_client.receive_message(
      queue_url: queue_url,
      max_number_of_messages: max_messages,
      wait_time_seconds: wait_time_seconds,
      message_attribute_names: ['All']
    )
    
    response.messages.first
  end

  def delete_from_sqs(queue_url:, receipt_handle:)
    sqs_client.delete_message(
      queue_url: queue_url,
      receipt_handle: receipt_handle
    )
  end

  def sns_topic_employee_data_raw
    ENV['SNS_TOPIC_EMPLOYEE_DATA_RAW']
  end

  def sqs_queue_assignments_completed
    ENV['SQS_QUEUE_ASSIGNMENTS_COMPLETED']
  end

  private

  def development_mode?
    Rails.env.development? || ENV['DEV_MODE'] == 'true' || ENV['AWS_REGION'].blank?
  end

  def process_assignments_directly(csv_data, previous_assignments)
    # Call CSV Parser Service directly
    csv_response = call_csv_parser_service(csv_data)
    
    unless csv_response[:success]
      return { success: false, error: csv_response[:error] }
    end

    # Call Assignment Service directly
    assignment_response = call_assignment_service(csv_response[:employees], previous_assignments)
    
    if assignment_response[:success]
      { success: true, assignments: assignment_response[:assignments] }
    else
      { success: false, error: assignment_response[:error] }
    end
  rescue HTTParty::Error => e
    { success: false, error: "Service unavailable: #{e.message}" }
  rescue StandardError => e
    { success: false, error: "Internal server error: #{e.message}" }
  end

  def call_csv_parser_service(csv_data)
    response = HTTParty.post(
      "#{csv_parser_service_url}/parse/employees",
      body: { csv_data: csv_data }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      parsed_response = JSON.parse(response.body, symbolize_names: true)
      # Convert CSV Parser response format to expected format
      if parsed_response[:employees]
        { success: true, employees: parsed_response[:employees] }
      else
        { success: false, error: parsed_response[:error] || 'No employees found' }
      end
    else
      { success: false, error: JSON.parse(response.body)['error'] }
    end
  end

  def call_assignment_service(employees, previous_assignments)
    response = HTTParty.post(
      "#{assignment_service_url}/api/v1/assignments/generate",
      body: { employees: employees, previous_assignments: previous_assignments }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      JSON.parse(response.body, symbolize_names: true)
    else
      { success: false, error: JSON.parse(response.body)['error'] }
    end
  end

  def csv_parser_service_url
    ENV['CSV_PARSER_SERVICE_URL'] || 'http://localhost:8080'
  end

  def assignment_service_url
    ENV['ASSIGNMENT_SERVICE_URL'] || 'http://localhost:3001'
  end
end
