class SecretSantaService
  def initialize
    @csv_parser_service_url = ENV['CSV_PARSER_SERVICE_URL'] || 'http://localhost:8080'
  end

  def generate_assignments(employees, previous_assignments)
    # Validate employees first
    validation_result = validate_employees(employees)
    unless validation_result[:valid]
      return {
        success: false,
        error: validation_result[:error],
        assignments: []
      }
    end

    # Try multiple times to generate valid assignments
    100.times do
      result = try_generate_assignments(employees, previous_assignments)
      return result if result[:success]
    end

    {
      success: false,
      error: 'Unable to generate valid assignments after multiple attempts',
      assignments: []
    }
  end

  def validate_employees(employees)
    if employees.empty?
      return { valid: false, error: 'Employee list cannot be empty' }
    end

    if employees.length < 2
      return { valid: false, error: 'Need at least 2 employees for Secret Santa' }
    end

    # Check for missing names or emails
    employees.each do |employee|
      if employee[:name].to_s.strip.empty?
        return { valid: false, error: 'invalid employee data: missing name' } 
      end
      if employee[:email].to_s.strip.empty?
        return { valid: false, error: 'invalid employee data: missing email' }
      end
    end

    # Check for duplicates
    names = employees.map { |e| e[:name] }
    emails = employees.map { |e| e[:email] }
    
    if names.uniq.length != names.length
      return { valid: false, error: 'duplicate employee data found' }
    end
    
    if emails.uniq.length != emails.length
      return { valid: false, error: 'duplicate employee data found' }
    end

    { valid: true, error: nil }
  end

  private

  def try_generate_assignments(employees, previous_assignments)
    # Create a circular assignment (each person gives to the next person)
    shuffled_employees = employees.shuffle
    assignments = []
    assigned_children = Set.new
    
    shuffled_employees.each_with_index do |employee, index|
      # The next person in the circle (with wraparound)
      next_index = (index + 1) % shuffled_employees.length
      secret_child = shuffled_employees[next_index]
      
      # Check if this assignment violates previous year's constraint
      forbidden_assignments = previous_assignments.select do |assignment|
        assignment[:employee_name] == employee[:name] && 
        assignment[:employee_email] == employee[:email] &&
        assignment[:secret_child_name] == secret_child[:name]
      end
      
      # If this assignment violates previous year's constraint or child is already assigned, try to find an alternative
      if forbidden_assignments.any? || assigned_children.include?(secret_child[:name])
        # Try to find a different assignment for this employee
        alternative_child = find_alternative_child(employee, shuffled_employees, previous_assignments, assigned_children)
        if alternative_child
          secret_child = alternative_child
        else
          # If no alternative found, this attempt fails
          return { success: false, error: 'Unable to generate valid assignments', assignments: [] }
        end
      end
      
      assignments << {
        employee_name: employee[:name],
        employee_email: employee[:email],
        secret_child_name: secret_child[:name],
        secret_child_email: secret_child[:email]
      }
      
      assigned_children.add(secret_child[:name])
    end
    
    {
      success: true,
      assignments: assignments,
      error: nil
    }
  end

  def find_alternative_child(employee, all_employees, previous_assignments, assigned_children)
    # Find all forbidden children for this employee
    forbidden_assignments = previous_assignments.select do |assignment|
      assignment[:employee_name] == employee[:name] && assignment[:employee_email] == employee[:email]
    end
    
    forbidden_names = forbidden_assignments.map { |assignment| assignment[:secret_child_name] }
    
    # Find available children (not self, not forbidden, and not already assigned)
    available_children = all_employees.reject do |child|
      child[:name] == employee[:name] || 
      forbidden_names.include?(child[:name]) ||
      assigned_children.include?(child[:name])
    end
    
    available_children.sample
  end
end
