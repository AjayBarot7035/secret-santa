require 'rails_helper'

RSpec.describe SecretSantaService do
  let(:service) { SecretSantaService.new }

  describe '#generate_assignments' do
    let(:employees) do
      [
        { name: 'John Doe', email: 'john.doe@example.com' },
        { name: 'Jane Smith', email: 'jane.smith@example.com' },
        { name: 'Bob Johnson', email: 'bob.johnson@example.com' },
        { name: 'Alice Brown', email: 'alice.brown@example.com' }
      ]
    end

    let(:previous_assignments) do
      [
        {
          employee_name: 'John Doe',
          employee_email: 'john.doe@example.com',
          secret_child_name: 'Jane Smith',
          secret_child_email: 'jane.smith@example.com'
        }
      ]
    end

    context 'with valid employees' do
      it 'generates assignments for all employees' do
        result = service.generate_assignments(employees, previous_assignments)

        expect(result[:success]).to be true
        expect(result[:assignments].length).to eq(4)
        expect(result[:error]).to be_nil
      end

      it 'ensures no employee is assigned to themselves' do
        result = service.generate_assignments(employees, previous_assignments)

        result[:assignments].each do |assignment|
          expect(assignment[:employee_name]).not_to eq(assignment[:secret_child_name])
          expect(assignment[:employee_email]).not_to eq(assignment[:secret_child_email])
        end
      end

      it 'avoids previous year assignments' do
        result = service.generate_assignments(employees, previous_assignments)

        # John Doe should not be assigned to Jane Smith again
        john_assignment = result[:assignments].find { |a| a[:employee_name] == 'John Doe' }
        expect(john_assignment[:secret_child_name]).not_to eq('Jane Smith')
      end

      it 'ensures each employee has exactly one secret child' do
        result = service.generate_assignments(employees, previous_assignments)

        employee_names = result[:assignments].map { |a| a[:employee_name] }
        secret_child_names = result[:assignments].map { |a| a[:secret_child_name] }

        expect(employee_names.uniq.length).to eq(4)
        expect(secret_child_names.uniq.length).to eq(4)
      end
    end

    context 'with insufficient employees' do
      let(:small_employee_list) do
        [
          { name: 'John Doe', email: 'john.doe@example.com' }
        ]
      end

      it 'returns an error for single employee' do
        result = service.generate_assignments(small_employee_list, [])

        expect(result[:success]).to be false
        expect(result[:error]).to include('at least 2 employees')
        expect(result[:assignments]).to be_empty
      end
    end

    context 'with duplicate employees' do
      let(:duplicate_employees) do
        [
          { name: 'John Doe', email: 'john.doe@example.com' },
          { name: 'John Doe', email: 'john.doe@example.com' },
          { name: 'Jane Smith', email: 'jane.smith@example.com' }
        ]
      end

      it 'returns an error for duplicate employees' do
        result = service.generate_assignments(duplicate_employees, [])

        expect(result[:success]).to be false
        expect(result[:error]).to include('Duplicate')
        expect(result[:assignments]).to be_empty
      end
    end

    context 'with invalid employee data' do
      let(:invalid_employees) do
        [
          { name: '', email: 'john.doe@example.com' },
          { name: 'Jane Smith', email: '' }
        ]
      end

      it 'returns an error for invalid employee data' do
        result = service.generate_assignments(invalid_employees, [])

        expect(result[:success]).to be false
        expect(result[:error]).to include('invalid')
        expect(result[:assignments]).to be_empty
      end
    end
  end

  describe '#validate_employees' do
    it 'returns true for valid employees' do
      employees = [
        { name: 'John Doe', email: 'john.doe@example.com' },
        { name: 'Jane Smith', email: 'jane.smith@example.com' }
      ]

      result = service.validate_employees(employees)
      expect(result[:valid]).to be true
      expect(result[:error]).to be_nil
    end

    it 'returns false for empty employee list' do
      result = service.validate_employees([])
      expect(result[:valid]).to be false
      expect(result[:error]).to include('empty')
    end

    it 'returns false for single employee' do
      employees = [{ name: 'John Doe', email: 'john.doe@example.com' }]
      result = service.validate_employees(employees)
      expect(result[:valid]).to be false
      expect(result[:error]).to include('at least 2')
    end

    it 'returns false for employees with missing names' do
      employees = [
        { name: '', email: 'john.doe@example.com' },
        { name: 'Jane Smith', email: 'jane.smith@example.com' }
      ]
      result = service.validate_employees(employees)
      expect(result[:valid]).to be false
      expect(result[:error]).to include('name')
    end

    it 'returns false for employees with missing emails' do
      employees = [
        { name: 'John Doe', email: '' },
        { name: 'Jane Smith', email: 'jane.smith@example.com' }
      ]
      result = service.validate_employees(employees)
      expect(result[:valid]).to be false
      expect(result[:error]).to include('email')
    end

    it 'returns false for duplicate employees' do
      employees = [
        { name: 'John Doe', email: 'john.doe@example.com' },
        { name: 'John Doe', email: 'john.doe@example.com' }
      ]
      result = service.validate_employees(employees)
      expect(result[:valid]).to be false
      expect(result[:error]).to include('Duplicate')
    end
  end
end
