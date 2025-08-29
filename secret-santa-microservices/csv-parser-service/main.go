package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"secret-santa/csv-parser-service/internal/csvparser"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
	snstypes "github.com/aws/aws-sdk-go-v2/service/sns/types"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	sqstypes "github.com/aws/aws-sdk-go-v2/service/sqs/types"
	"github.com/gorilla/mux"
)

type ParseResponse struct {
	Employees   []csvparser.Employee   `json:"employees,omitempty"`
	Assignments []csvparser.Assignment `json:"assignments,omitempty"`
	Message     string                 `json:"message"`
	Error       string                 `json:"error,omitempty"`
}

type SQSMessage struct {
	CSVData             string                 `json:"csv_data"`
	PreviousAssignments []csvparser.Assignment `json:"previous_assignments,omitempty"`
	RequestID           string                 `json:"request_id"`
	Timestamp           string                 `json:"timestamp"`
}

type SNSMessage struct {
	Success   bool                 `json:"success"`
	Employees []csvparser.Employee `json:"employees,omitempty"`
	RequestID string               `json:"request_id"`
	Timestamp string               `json:"timestamp"`
	Error     string               `json:"error,omitempty"`
}

var (
	sqsClient *sqs.Client
	snsClient *sns.Client
	devMode   bool
)

func main() {
	// Check if we're in development mode
	devMode = os.Getenv("DEV_MODE") == "true" || os.Getenv("AWS_REGION") == ""

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	r := mux.NewRouter()

	// Health check endpoint
	r.HandleFunc("/health", healthCheck).Methods("GET")

	if devMode {
		// Development mode: HTTP endpoints
		log.Println("Starting CSV Parser Service in DEVELOPMENT mode (HTTP endpoints)")
		r.HandleFunc("/parse/employees", parseEmployeesCSV).Methods("POST")
		r.HandleFunc("/parse/assignments", parseAssignmentsCSV).Methods("POST")
	} else {
		// Production mode: SQS/SNS
		log.Println("Starting CSV Parser Service in PRODUCTION mode (SQS/SNS)")

		// Initialize AWS clients
		cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(getAWSRegion()))
		if err != nil {
			log.Fatalf("Unable to load AWS config: %v", err)
		}

		sqsClient = sqs.NewFromConfig(cfg)
		snsClient = sns.NewFromConfig(cfg)

		// Start SQS message processor
		go processSQSMessages()
	}

	log.Printf("Starting CSV Parser Service on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := map[string]string{
		"status":  "healthy",
		"service": "csv-parser-service",
		"mode":    getMode(),
	}
	json.NewEncoder(w).Encode(response)
}

// Development mode HTTP endpoints
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

// Production mode SQS/SNS processing
func processSQSMessages() {
	queueURL := getSQSQueueURL()
	topicARN := getSNSTopicARN()

	for {
		// Receive message from SQS
		output, err := sqsClient.ReceiveMessage(context.TODO(), &sqs.ReceiveMessageInput{
			QueueUrl:              aws.String(queueURL),
			MaxNumberOfMessages:   1,
			WaitTimeSeconds:       20, // Long polling
			MessageAttributeNames: []string{"All"},
		})

		if err != nil {
			log.Printf("Error receiving message: %v", err)
			time.Sleep(5 * time.Second)
			continue
		}

		for _, message := range output.Messages {
			// Process the message
			if err := processMessage(message, topicARN, queueURL); err != nil {
				log.Printf("Error processing message: %v", err)
			}
		}
	}
}

func processMessage(message sqstypes.Message, topicARN, queueURL string) error {
	// Parse the message body
	var sqsMessage SQSMessage
	if err := json.Unmarshal([]byte(*message.Body), &sqsMessage); err != nil {
		log.Printf("Error unmarshaling message: %v", err)
		return deleteMessage(queueURL, *message.ReceiptHandle)
	}

	// Parse CSV data
	employees, err := csvparser.ParseEmployeesCSV(strings.NewReader(sqsMessage.CSVData))
	if err != nil {
		// Publish error to SNS
		snsMessage := SNSMessage{
			Success:   false,
			Error:     err.Error(),
			RequestID: sqsMessage.RequestID,
			Timestamp: time.Now().UTC().Format(time.RFC3339),
		}
		return publishToSNS(topicARN, snsMessage)
	}

	// Publish success to SNS
	snsMessage := SNSMessage{
		Success:   true,
		Employees: employees,
		RequestID: sqsMessage.RequestID,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	if err := publishToSNS(topicARN, snsMessage); err != nil {
		return err
	}

	// Delete the message from SQS
	return deleteMessage(queueURL, *message.ReceiptHandle)
}

func publishToSNS(topicARN string, message SNSMessage) error {
	messageBytes, err := json.Marshal(message)
	if err != nil {
		return err
	}

	_, err = snsClient.Publish(context.TODO(), &sns.PublishInput{
		TopicArn: aws.String(topicARN),
		Message:  aws.String(string(messageBytes)),
		MessageAttributes: map[string]snstypes.MessageAttributeValue{
			"service": {
				StringValue: aws.String("csv-parser"),
				DataType:    aws.String("String"),
			},
			"timestamp": {
				StringValue: aws.String(time.Now().UTC().Format(time.RFC3339)),
				DataType:    aws.String("String"),
			},
		},
	})

	return err
}

func deleteMessage(queueURL, receiptHandle string) error {
	_, err := sqsClient.DeleteMessage(context.TODO(), &sqs.DeleteMessageInput{
		QueueUrl:      aws.String(queueURL),
		ReceiptHandle: aws.String(receiptHandle),
	})
	return err
}

func getAWSRegion() string {
	if region := os.Getenv("AWS_REGION"); region != "" {
		return region
	}
	return "us-east-1"
}

func getSQSQueueURL() string {
	return os.Getenv("SQS_QUEUE_CSV_PARSER")
}

func getSNSTopicARN() string {
	return os.Getenv("SNS_TOPIC_EMPLOYEE_DATA_PARSED")
}

func getMode() string {
	if devMode {
		return "development"
	}
	return "production"
}
