class Api::V1::AssignmentsController < ApplicationController
  def generate
    employees = params[:employees] || []
    previous_assignments = params[:previous_assignments] || []

    service = SecretSantaService.new
    result = service.generate_assignments(employees, previous_assignments)

    if result[:success]
      render json: { success: true, assignments: result[:assignments] }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { success: false, error: "Internal server error: #{e.message}" }, status: :internal_server_error
  end

  def health
    render json: { status: 'healthy', service: 'Secret Santa Assignment Service' }
  end
end
