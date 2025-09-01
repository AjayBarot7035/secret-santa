package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"

	"secret-santa/csv-parser-service/internal/csvparser"

	"github.com/gorilla/mux"
)

type ParseResponse struct {
	Employees   []csvparser.Employee   `json:"employees,omitempty"`
	Assignments []csvparser.Assignment `json:"assignments,omitempty"`
	Message     string                 `json:"message"`
	Error       string                 `json:"error,omitempty"`
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	r := mux.NewRouter()

	// Health check endpoint
	r.HandleFunc("/health", healthCheck).Methods("GET")

	// HTTP endpoints
	log.Println("Starting CSV Parser Service (HTTP endpoints)")
	r.HandleFunc("/parse/employees", parseEmployeesCSV).Methods("POST")
	r.HandleFunc("/parse/assignments", parseAssignmentsCSV).Methods("POST")

	log.Printf("Starting CSV Parser Service on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := map[string]string{
		"status":  "healthy",
		"service": "csv-parser-service",
	}
	json.NewEncoder(w).Encode(response)
}

// HTTP endpoints
func parseEmployeesCSV(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var request struct {
		CSVData string `json:"csv_data"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	if request.CSVData == "" {
		http.Error(w, "CSV data is required", http.StatusBadRequest)
		return
	}

	employees, err := csvparser.ParseEmployeesCSV(strings.NewReader(request.CSVData))
	if err != nil {
		response := ParseResponse{
			Message: "Failed to parse employees CSV",
			Error:   err.Error(),
		}
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(response)
		return
	}

	response := ParseResponse{
		Employees: employees,
		Message:   "Successfully parsed employees CSV",
	}
	json.NewEncoder(w).Encode(response)
}

func parseAssignmentsCSV(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var request struct {
		CSVData string `json:"csv_data"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	if request.CSVData == "" {
		http.Error(w, "CSV data is required", http.StatusBadRequest)
		return
	}

	assignments, err := csvparser.ParseAssignmentsCSV(strings.NewReader(request.CSVData))
	if err != nil {
		response := ParseResponse{
			Message: "Failed to parse assignments CSV",
			Error:   err.Error(),
		}
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(response)
		return
	}

	response := ParseResponse{
		Assignments: assignments,
		Message:     "Successfully parsed assignments CSV",
	}
	json.NewEncoder(w).Encode(response)
}
