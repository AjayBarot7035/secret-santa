package csvparser

import (
	"strings"
	"testing"
)

func TestParseEmployeesCSV_ValidData(t *testing.T) {
	// Arrange
	csvData := `Employee_Name,Employee_EmailID
John Doe,john.doe@example.com
Jane Smith,jane.smith@example.com
Bob Johnson,bob.johnson@example.com`

	reader := strings.NewReader(csvData)

	// Act
	employees, err := ParseEmployeesCSV(reader)

	// Assert
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}

	if len(employees) != 3 {
		t.Errorf("Expected 3 employees, got %d", len(employees))
	}

	expectedEmployees := []Employee{
		{Name: "John Doe", Email: "john.doe@example.com"},
		{Name: "Jane Smith", Email: "jane.smith@example.com"},
		{Name: "Bob Johnson", Email: "bob.johnson@example.com"},
	}

	for i, expected := range expectedEmployees {
		if employees[i].Name != expected.Name {
			t.Errorf("Expected name %s, got %s", expected.Name, employees[i].Name)
		}
		if employees[i].Email != expected.Email {
			t.Errorf("Expected email %s, got %s", expected.Email, employees[i].Email)
		}
	}
}

func TestParseEmployeesCSV_EmptyFile(t *testing.T) {
	// Arrange
	csvData := `Employee_Name,Employee_EmailID`
	reader := strings.NewReader(csvData)

	// Act
	employees, err := ParseEmployeesCSV(reader)

	// Assert
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}

	if len(employees) != 0 {
		t.Errorf("Expected 0 employees, got %d", len(employees))
	}
}

func TestParseEmployeesCSV_InvalidFormat(t *testing.T) {
	// Arrange
	csvData := `Employee_Name` // Missing email column
	reader := strings.NewReader(csvData)

	// Act
	employees, err := ParseEmployeesCSV(reader)

	// Assert
	if err == nil {
		t.Error("Expected error for invalid CSV format, got nil")
	}

	if len(employees) != 0 {
		t.Errorf("Expected 0 employees, got %d", len(employees))
	}
}

func TestParseEmployeesCSV_EmptyRows(t *testing.T) {
	// Arrange
	csvData := `Employee_Name,Employee_EmailID
John Doe,john.doe@example.com
,
Jane Smith,jane.smith@example.com
Bob Johnson,`
	reader := strings.NewReader(csvData)

	// Act
	employees, err := ParseEmployeesCSV(reader)

	// Assert
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}

	// Should have 2 valid employees (John Doe and Jane Smith)
	if len(employees) != 2 {
		t.Errorf("Expected 2 employees, got %d", len(employees))
	}

	if employees[0].Name != "John Doe" {
		t.Errorf("Expected name John Doe, got %s", employees[0].Name)
	}
}

func TestParseAssignmentsCSV_ValidData(t *testing.T) {
	// Arrange
	csvData := `Employee_Name,Employee_EmailID,Secret_Child_Name,Secret_Child_EmailID
John Doe,john.doe@example.com,Jane Smith,jane.smith@example.com
Jane Smith,jane.smith@example.com,Bob Johnson,bob.johnson@example.com`
	reader := strings.NewReader(csvData)

	// Act
	assignments, err := ParseAssignmentsCSV(reader)

	// Assert
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}

	if len(assignments) != 2 {
		t.Errorf("Expected 2 assignments, got %d", len(assignments))
	}

	expectedAssignments := []Assignment{
		{
			EmployeeName:     "John Doe",
			EmployeeEmail:    "john.doe@example.com",
			SecretChildName:  "Jane Smith",
			SecretChildEmail: "jane.smith@example.com",
		},
		{
			EmployeeName:     "Jane Smith",
			EmployeeEmail:    "jane.smith@example.com",
			SecretChildName:  "Bob Johnson",
			SecretChildEmail: "bob.johnson@example.com",
		},
	}

	for i, expected := range expectedAssignments {
		if assignments[i].EmployeeName != expected.EmployeeName {
			t.Errorf("Expected employee name %s, got %s", expected.EmployeeName, assignments[i].EmployeeName)
		}
		if assignments[i].SecretChildName != expected.SecretChildName {
			t.Errorf("Expected secret child name %s, got %s", expected.SecretChildName, assignments[i].SecretChildName)
		}
	}
}

func TestParseAssignmentsCSV_InvalidFormat(t *testing.T) {
	// Arrange
	csvData := `Employee_Name,Employee_EmailID` // Missing secret child columns
	reader := strings.NewReader(csvData)

	// Act
	assignments, err := ParseAssignmentsCSV(reader)

	// Assert
	if err == nil {
		t.Error("Expected error for invalid CSV format, got nil")
	}

	if len(assignments) != 0 {
		t.Errorf("Expected 0 assignments, got %d", len(assignments))
	}
}
