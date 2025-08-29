package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealthCheck(t *testing.T) {
	// Arrange
	req, err := http.NewRequest("GET", "/health", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(healthCheck)

	// Act
	handler.ServeHTTP(rr, req)

	// Assert
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var response map[string]string
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}

	if response["status"] != "healthy" {
		t.Errorf("Expected status 'healthy', got %s", response["status"])
	}

	if response["service"] != "csv-parser-service" {
		t.Errorf("Expected service 'csv-parser-service', got %s", response["service"])
	}
}

func TestParseEmployeesCSV_ValidData(t *testing.T) {
	// Arrange
	csvData := `Employee_Name,Employee_EmailID
John Doe,john.doe@example.com
Jane Smith,jane.smith@example.com`

	req, err := http.NewRequest("POST", "/parse/employees", strings.NewReader(csvData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "text/csv")

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(parseEmployeesCSV)

	// Act
	handler.ServeHTTP(rr, req)

	// Assert
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var response ParseResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}

	if len(response.Employees) != 2 {
		t.Errorf("Expected 2 employees, got %d", len(response.Employees))
	}

	if response.Employees[0].Name != "John Doe" {
		t.Errorf("Expected first employee name 'John Doe', got %s", response.Employees[0].Name)
	}

	if response.Employees[1].Name != "Jane Smith" {
		t.Errorf("Expected second employee name 'Jane Smith', got %s", response.Employees[1].Name)
	}
}

func TestParseEmployeesCSV_InvalidData(t *testing.T) {
	// Arrange
	csvData := `Employee_Name` // Missing email column

	req, err := http.NewRequest("POST", "/parse/employees", strings.NewReader(csvData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "text/csv")

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(parseEmployeesCSV)

	// Act
	handler.ServeHTTP(rr, req)

	// Assert
	if status := rr.Code; status != http.StatusBadRequest {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusBadRequest)
	}

	var response ParseResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}

	if response.Error == "" {
		t.Error("Expected error message, got empty string")
	}
}

func TestParseAssignmentsCSV_ValidData(t *testing.T) {
	// Arrange
	csvData := `Employee_Name,Employee_EmailID,Secret_Child_Name,Secret_Child_EmailID
John Doe,john.doe@example.com,Jane Smith,jane.smith@example.com`

	req, err := http.NewRequest("POST", "/parse/assignments", strings.NewReader(csvData))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "text/csv")

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(parseAssignmentsCSV)

	// Act
	handler.ServeHTTP(rr, req)

	// Assert
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var response ParseResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &response); err != nil {
		t.Errorf("Failed to parse response: %v", err)
	}

	if len(response.Assignments) != 1 {
		t.Errorf("Expected 1 assignment, got %d", len(response.Assignments))
	}

	if response.Assignments[0].EmployeeName != "John Doe" {
		t.Errorf("Expected employee name 'John Doe', got %s", response.Assignments[0].EmployeeName)
	}

	if response.Assignments[0].SecretChildName != "Jane Smith" {
		t.Errorf("Expected secret child name 'Jane Smith', got %s", response.Assignments[0].SecretChildName)
	}
}
