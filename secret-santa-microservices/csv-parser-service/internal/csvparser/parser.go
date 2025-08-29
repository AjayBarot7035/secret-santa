package csvparser

import (
	"encoding/csv"
	"fmt"
	"io"
	"strings"
)

type Employee struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

type Assignment struct {
	EmployeeName     string `json:"employee_name"`
	EmployeeEmail    string `json:"employee_email"`
	SecretChildName  string `json:"secret_child_name"`
	SecretChildEmail string `json:"secret_child_email"`
}

// ParseEmployeesCSV parses a CSV file containing employee information
func ParseEmployeesCSV(reader io.Reader) ([]Employee, error) {
	csvReader := csv.NewReader(reader)
	
	// Read header
	header, err := csvReader.Read()
	if err != nil {
		return nil, fmt.Errorf("error reading CSV header: %w", err)
	}
	
	// Validate header
	if len(header) < 2 {
		return nil, fmt.Errorf("invalid CSV format: expected at least 2 columns (name, email)")
	}
	
	var employees []Employee
	
	// Read data rows
	for {
		record, err := csvReader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("error reading CSV row: %w", err)
		}
		
		if len(record) < 2 {
			continue // Skip incomplete rows
		}
		
		employee := Employee{
			Name:  strings.TrimSpace(record[0]),
			Email: strings.TrimSpace(record[1]),
		}
		
		// Basic validation
		if employee.Name == "" || employee.Email == "" {
			continue // Skip rows with empty name or email
		}
		
		employees = append(employees, employee)
	}
	
	return employees, nil
}

// ParseAssignmentsCSV parses a CSV file containing previous year's assignments
func ParseAssignmentsCSV(reader io.Reader) ([]Assignment, error) {
	csvReader := csv.NewReader(reader)
	
	// Read header
	header, err := csvReader.Read()
	if err != nil {
		return nil, fmt.Errorf("error reading CSV header: %w", err)
	}
	
	// Validate header
	if len(header) < 4 {
		return nil, fmt.Errorf("invalid CSV format: expected at least 4 columns (employee_name, employee_email, secret_child_name, secret_child_email)")
	}
	
	var assignments []Assignment
	
	// Read data rows
	for {
		record, err := csvReader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("error reading CSV row: %w", err)
		}
		
		if len(record) < 4 {
			continue // Skip incomplete rows
		}
		
		assignment := Assignment{
			EmployeeName:     strings.TrimSpace(record[0]),
			EmployeeEmail:    strings.TrimSpace(record[1]),
			SecretChildName:  strings.TrimSpace(record[2]),
			SecretChildEmail: strings.TrimSpace(record[3]),
		}
		
		// Basic validation
		if assignment.EmployeeName == "" || assignment.EmployeeEmail == "" ||
			assignment.SecretChildName == "" || assignment.SecretChildEmail == "" {
			continue // Skip rows with empty fields
		}
		
		assignments = append(assignments, assignment)
	}
	
	return assignments, nil
}
