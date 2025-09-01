class Api::V1::SecretSantaController < ApplicationController
  def generate_assignments
    employees = params[:employees]
    previous_assignments = params[:previous_assignments] || []

    # Direct HTTP calls to services
    result = process_assignments_directly(employees, previous_assignments)
    render json: result
  end

  def health
    render json: { status: 'healthy', service: 'Secret Santa API Gateway' }
  end

  private

  def process_assignments_directly(employees, previous_assignments)
    # Call Assignment Service directly with employees data
    assignment_response = call_assignment_service(employees, previous_assignments)

    if assignment_response[:success]
      # Transform the response format to match UI expectations
      transformed_assignments = assignment_response[:assignments].map do |assignment|
        {
          santa_name: assignment[:employee_name],
          santa_email: assignment[:employee_email],
          secret_child_name: assignment[:secret_child_name],
          secret_child_email: assignment[:secret_child_email]
        }
      end
      { success: true, assignments: transformed_assignments }
    else
      { success: false, error: assignment_response[:error] }
    end
  rescue HTTParty::Error => e
    { success: false, error: "Service unavailable: #{e.message}" }
  rescue StandardError => e
    { success: false, error: "Internal server error: #{e.message}" }
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

  def assignment_service_url
    ENV['ASSIGNMENT_SERVICE_URL'] || 'http://localhost:3001'
  end
end
