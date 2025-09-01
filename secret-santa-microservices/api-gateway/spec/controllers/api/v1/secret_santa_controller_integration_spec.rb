require 'rails_helper'

RSpec.describe 'Secret Santa API Integration', type: :request do
  describe 'GET /api/v1/secret_santa/health' do
    it 'returns health status' do
      get '/api/v1/secret_santa/health', headers: { 'HOST' => 'localhost' }
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('healthy')
      expect(json_response['service']).to eq('Secret Santa API Gateway')
    end
  end

  describe 'POST /api/v1/secret_santa/generate_assignments' do
    let(:valid_employees) do
      [
        { name: 'John Doe', email: 'john@example.com' },
        { name: 'Jane Smith', email: 'jane@example.com' },
        { name: 'Bob Johnson', email: 'bob@example.com' },
        { name: 'Alice Brown', email: 'alice@example.com' }
      ]
    end

    context 'when services are available' do
      before do
        # Mock the assignment service response
        stub_request(:post, "http://localhost:3001/api/v1/assignments/generate")
          .with(
            body: { employees: valid_employees, previous_assignments: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 200,
            body: {
              success: true,
              assignments: [
                { employee_name: 'John Doe', employee_email: 'john@example.com', secret_child_name: 'Jane Smith', secret_child_email: 'jane@example.com' },
                { employee_name: 'Jane Smith', employee_email: 'jane@example.com', secret_child_name: 'Bob Johnson', secret_child_email: 'bob@example.com' },
                { employee_name: 'Bob Johnson', employee_email: 'bob@example.com', secret_child_name: 'Alice Brown', secret_child_email: 'alice@example.com' },
                { employee_name: 'Alice Brown', employee_email: 'alice@example.com', secret_child_name: 'John Doe', secret_child_email: 'john@example.com' }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'successfully generates assignments' do
        post '/api/v1/secret_santa/generate_assignments', 
          params: { employees: valid_employees, previous_assignments: [] }.to_json,
          headers: { 'Content-Type' => 'application/json', 'HOST' => 'localhost' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['assignments'].length).to eq(4)
        expect(json_response['assignments'].first['santa_name']).to eq('John Doe')
      end
    end

    context 'when assignment service is unavailable' do
      before do
        stub_request(:post, "http://localhost:3001/api/v1/assignments/generate")
          .to_raise(HTTParty::Error.new('Connection refused'))
      end

      it 'returns service unavailable error' do
        post '/api/v1/secret_santa/generate_assignments', 
          params: { employees: valid_employees, previous_assignments: [] }.to_json,
          headers: { 'Content-Type' => 'application/json', 'HOST' => 'localhost' }
        
        expect(response).to have_http_status(:ok) # The controller handles errors gracefully
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to include('Service unavailable')
      end
    end
  end
end
