// Global variables
let employees = [];
let assignments = [];
let isGenerating = false;
let csvData = null;
let previousAssignments = [];

// API Configuration
const API_BASE_URL = 'http://localhost:3000/api/v1';

// DOM Elements
const employeeNameInput = document.getElementById('employeeName');
const employeeEmailInput = document.getElementById('employeeEmail');
const employeeList = document.getElementById('employees');
const employeeCount = document.getElementById('employeeCount');
const generateBtn = document.getElementById('generateBtn');
const animationSection = document.getElementById('animationSection');
const resultsSection = document.getElementById('resultsSection');
const errorSection = document.getElementById('errorSection');
const progressFill = document.getElementById('progressFill');
const statusText = document.getElementById('statusText');
const assignmentsContainer = document.getElementById('assignmentsContainer');
const errorMessage = document.getElementById('errorMessage');

// Event Listeners
document.addEventListener('DOMContentLoaded', function() {
    // Start the Santa journey
    startSantaJourney();
    
    // Add enter key support for inputs
    employeeNameInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            employeeEmailInput.focus();
        }
    });
    
    employeeEmailInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            addEmployee();
        }
    });
    
    // CSV file upload handling
    setupCSVUpload();
    
    // Previous assignments upload handling (with delay to ensure DOM is ready)
    setTimeout(() => {
        setupPreviousAssignmentsUpload();
    }, 100);
});

// Santa Journey Functions
function startSantaJourney() {
    const santaTeam = document.getElementById('santaTeam');
    
    // Start Santa running across the screen
    setTimeout(() => {
        santaTeam.classList.add('running');
        
        // Stop Santa in the middle after 3 seconds
        setTimeout(() => {
            santaTeam.classList.remove('running');
            santaTeam.classList.add('stopped');
            
            // Show Santa's message
            setTimeout(() => {
                document.getElementById('santaStops').style.display = 'block';
            }, 500);
        }, 3000);
    }, 1000);
}

function giveListToSanta() {
    document.getElementById('santaStops').style.display = 'none';
    document.getElementById('listInputArea').style.display = 'block';
    
    // Add some Santa magic
    const santaTeam = document.getElementById('santaTeam');
    santaTeam.style.transform = 'translate(-50%, -50%) scale(1.1)';
    setTimeout(() => {
        santaTeam.style.transform = 'translate(-50%, -50%) scale(1)';
    }, 200);
}

function giveListToReindeer() {
    document.getElementById('santaStops').style.display = 'none';
    document.getElementById('listInputArea').style.display = 'block';
    
    // Add some reindeer magic
    const santaTeam = document.getElementById('santaTeam');
    santaTeam.style.transform = 'translate(-50%, -50%) rotate(5deg)';
    setTimeout(() => {
        santaTeam.style.transform = 'translate(-50%, -50%) rotate(0deg)';
    }, 200);
}

function submitListToSanta() {
    if (employees.length < 2) {
        showError('You need at least 2 participants for Secret Santa');
        return;
    }
    
    document.getElementById('listInputArea').style.display = 'none';
    document.getElementById('assignmentReady').style.display = 'block';
    document.getElementById('readyCount').textContent = employees.length;
    
    // Santa celebrates
    const santaTeam = document.getElementById('santaTeam');
    santaTeam.style.transform = 'translate(-50%, -50%) scale(1.2)';
    setTimeout(() => {
        santaTeam.style.transform = 'translate(-50%, -50%) scale(1)';
    }, 300);
}

function startSantaAssignment() {
    document.getElementById('assignmentReady').style.display = 'none';
    document.getElementById('animationSection').style.display = 'block';
    
    // Make Santa fly away to his workshop
    const santaTeam = document.getElementById('santaTeam');
    santaTeam.classList.remove('stopped');
    santaTeam.classList.add('running');
    
    // Start the assignment process
    generateAssignments();
}

function resetList() {
    employees = [];
    updateEmployeeDisplay();
    document.getElementById('listInputArea').style.display = 'none';
    document.getElementById('santaStops').style.display = 'block';
}

// Add employee to the list
function addEmployee() {
    const name = employeeNameInput.value.trim();
    const email = employeeEmailInput.value.trim();
    
    if (!name || !email) {
        showError('Please enter both name and email');
        return;
    }
    
    if (!isValidEmail(email)) {
        showError('Please enter a valid email address');
        return;
    }
    
    if (employees.some(emp => emp.email === email)) {
        showError('A participant with this email already exists');
        return;
    }
    
    const employee = { name, email };
    employees.push(employee);
    
    // Clear inputs
    employeeNameInput.value = '';
    employeeEmailInput.value = '';
    employeeNameInput.focus();
    
    // Update display
    updateEmployeeDisplay();
    hideError();
}

// Remove employee from the list
function removeEmployee(email) {
    employees = employees.filter(emp => emp.email !== email);
    updateEmployeeDisplay();
}

// Update employee display
function updateEmployeeDisplay() {
    employeeCount.textContent = employees.length;
    
    const employeesContainer = document.getElementById('employees');
    if (employeesContainer) {
        employeesContainer.innerHTML = employees.map(emp => `
            <div class="employee-card-mini">
                <div class="employee-info">
                    <strong>${emp.name}</strong>
                    <small>${emp.email}</small>
                </div>
                <button class="remove-btn" onclick="removeEmployee('${emp.email}')" style="background: #dc3545; color: white; border: none; border-radius: 50%; width: 32px; height: 32px; cursor: pointer; font-size: 1rem; display: flex; align-items: center; justify-content: center; transition: all 0.2s ease;">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `).join('');
    }
    
    // Update submit button state
    const submitListBtn = document.getElementById('submitListBtn');
    if (submitListBtn) {
        submitListBtn.disabled = employees.length < 2;
    }
}

// Generate Secret Santa assignments
async function generateAssignments() {
    if (employees.length < 2) {
        showError('You need at least 2 participants for Secret Santa');
        return;
    }
    
    if (isGenerating) return;
    
    isGenerating = true;
    showAnimation();
    
    try {
        // Simulate microservices processing with animations
        await simulateMicroservicesProcess();
        
        // Make actual API call
        const response = await fetch(`${API_BASE_URL}/secret_santa/generate_assignments`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ 
                employees: employees,
                previous_assignments: previousAssignments
            })
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        
        if (data.success) {
            assignments = data.assignments || [];
            showResults();
        } else {
            throw new Error(data.error || 'Failed to generate assignments');
        }
        
    } catch (error) {
        console.error('Error:', error);
        showError(`Failed to generate assignments: ${error.message}`);
    } finally {
        isGenerating = false;
        hideAnimation();
    }
}

// Simulate Santa's workshop processing with animations
async function simulateMicroservicesProcess() {
    const steps = [
        { progress: 20, status: 'Santa is reading the list...', service: 1 },
        { progress: 35, status: 'Checking who\'s been naughty or nice...', service: 1 },
        { progress: 50, status: 'Santa is checking the list twice...', service: 2 },
        { progress: 65, status: 'Making Secret Santa assignments...', service: 2 },
        { progress: 80, status: 'Wrapping up the assignments...', service: 3 },
        { progress: 100, status: 'Ho Ho Ho! Assignments are ready!', service: 3 }
    ];
    
    for (let i = 0; i < steps.length; i++) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        updateProgress(steps[i].progress, steps[i].status, steps[i].service);
    }
}

// Update progress bar and status
function updateProgress(progress, status, service = null) {
    progressFill.style.width = `${progress}%`;
    statusText.textContent = status;
    
    // Update Santa's workshop status indicators
    if (service) {
        // Reset all status items
        document.querySelectorAll('.status-item').forEach(item => {
            item.classList.remove('active', 'completed');
        });
        
        // Mark current step as active
        if (service <= 3) {
            const statusItem = document.getElementById(`status${service}`);
            if (statusItem) {
                statusItem.classList.add('active');
            }
        }
        
        // Mark previous steps as completed
        for (let i = 1; i < service; i++) {
            const statusItem = document.getElementById(`status${i}`);
            if (statusItem) {
                statusItem.classList.remove('active');
                statusItem.classList.add('completed');
            }
        }
    }
}

// Show animation section
function showAnimation() {
    animationSection.style.display = 'block';
    resultsSection.style.display = 'none';
    errorSection.style.display = 'none';
    updateProgress(0, 'Initializing microservices...');
}

// Hide animation section
function hideAnimation() {
    animationSection.style.display = 'none';
}

// Show results
function showResults() {
    resultsSection.style.display = 'block';
    errorSection.style.display = 'none';
    
    assignmentsContainer.innerHTML = assignments.map(assignment => `
        <div class="assignment-card">
            <div class="santa-icon">🎅</div>
            <h3>${assignment.santa_name}</h3>
            <div class="arrow">⬇️</div>
            <h3>${assignment.secret_child_name}</h3>
            <p><i class="fas fa-envelope"></i> ${assignment.secret_child_email}</p>
        </div>
    `).join('');
    
    // Add success animation
    resultsSection.classList.add('success-animation');
    setTimeout(() => {
        resultsSection.classList.remove('success-animation');
    }, 500);
}

// Show error
function showError(message) {
    errorMessage.textContent = message;
    errorSection.style.display = 'block';
    resultsSection.style.display = 'none';
    animationSection.style.display = 'none';
}

// Hide error
function hideError() {
    errorSection.style.display = 'none';
}

// Clear all data
function clearAll() {
    employees = [];
    assignments = [];
    previousAssignments = [];
    updateEmployeeDisplay();
    hideError();
    resultsSection.style.display = 'none';
    animationSection.style.display = 'none';
    employeeNameInput.focus();
    
    // Clear file inputs
    document.getElementById('csvFile').value = '';
    document.getElementById('previousCsvFile').value = '';
}

// Export to CSV
function exportToCSV() {
    if (assignments.length === 0) {
        showError('No assignments to export');
        return;
    }
    
    // Validate assignments data
    const validAssignments = assignments.filter(assignment => {
        return assignment.santa_name && assignment.santa_email && 
               assignment.secret_child_name && assignment.secret_child_email;
    });
    
    if (validAssignments.length === 0) {
        showError('No valid assignments to export');
        return;
    }
    
    const csvContent = [
        'Employee_Name,Employee_EmailID,Secret_Child_Name,Secret_Child_EmailID',
        ...validAssignments.map(assignment => {
            // Ensure each field is properly separated and escaped
            const row = [
                assignment.santa_name || '',
                assignment.santa_email || '',
                assignment.secret_child_name || '',
                assignment.secret_child_email || ''
            ].map(field => {
                // Escape quotes and wrap in quotes if contains comma
                if (field && (field.includes(',') || field.includes('"'))) {
                    return `"${field.replace(/"/g, '""')}"`;
                }
                return field;
            }).join(',');
            
            return row;
        })
    ].join('\n');
    
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'secret_santa_assignments.csv';
    a.click();
    window.URL.revokeObjectURL(url);
}

// Share results
function shareResults() {
    if (assignments.length === 0) {
        showError('No assignments to share');
        return;
    }
    
    const text = `Secret Santa Assignments:\n\n${assignments.map(assignment => 
        `${assignment.santa_name} → ${assignment.secret_child_name}`
    ).join('\n')}`;
    
    if (navigator.share) {
        navigator.share({
            title: 'Secret Santa Assignments',
            text: text
        });
    } else {
        // Fallback: copy to clipboard
        navigator.clipboard.writeText(text).then(() => {
            alert('Assignments copied to clipboard!');
        });
    }
}

// Load sample data for demo
function loadSampleData() {
    const sampleEmployees = [
        { name: 'John Doe', email: 'john@example.com' },
        { name: 'Jane Smith', email: 'jane@example.com' },
        { name: 'Bob Johnson', email: 'bob@example.com' },
        { name: 'Alice Brown', email: 'alice@example.com' },
        { name: 'Charlie Wilson', email: 'charlie@example.com' }
    ];
    
    employees = sampleEmployees;
    updateEmployeeDisplay();
}

// CSV Upload Functions
function setupCSVUpload() {
    const uploadZone = document.getElementById('uploadZone');
    const csvFile = document.getElementById('csvFile');
    const chooseFileBtn = document.getElementById('chooseFileBtn');
    
    if (uploadZone && csvFile) {
        // File input change event
        csvFile.addEventListener('change', handleFileSelect);
        
        // Drag and drop events
        uploadZone.addEventListener('dragover', handleDragOver);
        uploadZone.addEventListener('dragleave', handleDragLeave);
        uploadZone.addEventListener('drop', handleDrop);
        
        // Only the "Choose CSV File" button triggers file picker
        if (chooseFileBtn) {
            chooseFileBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                csvFile.click();
            });
        }
    }
}

// Previous Assignments Upload Functions
function setupPreviousAssignmentsUpload() {
    const previousUploadZone = document.getElementById('previousUploadZone');
    const previousCsvFile = document.getElementById('previousCsvFile');
    const choosePreviousFileBtn = document.getElementById('choosePreviousFileBtn');
    
    if (previousUploadZone && previousCsvFile) {
        // File input change event
        previousCsvFile.addEventListener('change', handlePreviousFileSelect);
        
        // Drag and drop events
        previousUploadZone.addEventListener('dragover', handlePreviousDragOver);
        previousUploadZone.addEventListener('dragleave', handlePreviousDragLeave);
        previousUploadZone.addEventListener('drop', handlePreviousDrop);
        
        // Only the "Choose Previous Assignments" button triggers file picker
        if (choosePreviousFileBtn) {
            choosePreviousFileBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                e.preventDefault();
                previousCsvFile.click();
            });
        }
    }
}

function handlePreviousDragOver(e) {
    e.preventDefault();
    const previousUploadZone = document.getElementById('previousUploadZone');
    if (previousUploadZone) {
        previousUploadZone.classList.add('dragover');
    }
}

function handlePreviousDragLeave(e) {
    e.preventDefault();
    const previousUploadZone = document.getElementById('previousUploadZone');
    if (previousUploadZone) {
        previousUploadZone.classList.remove('dragover');
    }
}

function handlePreviousDrop(e) {
    e.preventDefault();
    const previousUploadZone = document.getElementById('previousUploadZone');
    if (previousUploadZone) {
        previousUploadZone.classList.remove('dragover');
    }
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        handlePreviousFile(files[0]);
    }
}

function handlePreviousFileSelect(e) {
    const file = e.target.files[0];
    if (file) {
        handlePreviousFile(file);
    }
}

function handlePreviousFile(file) {
    if (!file.name.toLowerCase().endsWith('.csv')) {
        showError('Please select a valid CSV file for previous assignments');
        return;
    }
    
    const reader = new FileReader();
    reader.onload = function(e) {
        const csvContent = e.target.result;
        importPreviousAssignments(csvContent);
    };
    reader.readAsText(file);
}

function importPreviousAssignments(csvContent) {
    if (!csvContent) {
        showError('No CSV data to import for previous assignments');
        return;
    }
    
    try {
        const lines = csvContent.split('\n').filter(line => line.trim());
        const newPreviousAssignments = [];
        
        // Skip header if it exists
        const startIndex = lines[0].toLowerCase().includes('employee_name') && 
                          lines[0].toLowerCase().includes('secret_child_name') ? 1 : 0;
        
        for (let i = startIndex; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line) {
                const parts = line.split(',').map(part => part.trim());
                if (parts.length >= 4) {
                    const assignment = {
                        employee_name: parts[0],
                        employee_email: parts[1],
                        secret_child_name: parts[2],
                        secret_child_email: parts[3]
                    };
                    newPreviousAssignments.push(assignment);
                }
            }
        }
        
        if (newPreviousAssignments.length === 0) {
            showError('No valid previous assignments found in CSV file');
            return;
        }
        
        previousAssignments = newPreviousAssignments;
        hideError();
        
        // Show success message
        showSuccess(`Successfully imported ${newPreviousAssignments.length} previous assignments!`);
        
    } catch (error) {
        showError('Error parsing previous assignments CSV file: ' + error.message);
    }
}

function handleDragOver(e) {
    e.preventDefault();
    const uploadZone = document.getElementById('uploadZone');
    if (uploadZone) {
        uploadZone.classList.add('dragover');
    }
}

function handleDragLeave(e) {
    e.preventDefault();
    const uploadZone = document.getElementById('uploadZone');
    if (uploadZone) {
        uploadZone.classList.remove('dragover');
    }
}

function handleDrop(e) {
    e.preventDefault();
    const uploadZone = document.getElementById('uploadZone');
    if (uploadZone) {
        uploadZone.classList.remove('dragover');
    }
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        handleFile(files[0]);
    }
}

function handleFileSelect(e) {
    const file = e.target.files[0];
    if (file) {
        handleFile(file);
    }
}

function handleFile(file) {
    if (!file.name.toLowerCase().endsWith('.csv')) {
        showError('Please select a valid CSV file');
        return;
    }
    
    const reader = new FileReader();
    reader.onload = function(e) {
        csvData = e.target.result;
        showCSVPreview(csvData);
    };
    reader.readAsText(file);
}

function showCSVPreview(csvContent) {
    // For the new interface, we'll directly import the CSV
    importCSVFromContent(csvContent);
}

function importCSVFromContent(csvContent) {
    if (!csvContent) {
        showError('No CSV data to import');
        return;
    }
    
    try {
        const lines = csvContent.split('\n').filter(line => line.trim());
        const newEmployees = [];
        
        // Skip header if it exists
        const startIndex = lines[0].toLowerCase().includes('name') && lines[0].toLowerCase().includes('email') ? 1 : 0;
        
        for (let i = startIndex; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line) {
                const parts = line.split(',').map(part => part.trim());
                if (parts.length >= 2) {
                    const name = parts[0];
                    const email = parts[1];
                    
                    if (name && email && isValidEmail(email)) {
                        newEmployees.push({ name, email });
                    }
                }
            }
        }
        
        if (newEmployees.length === 0) {
            showError('No valid participants found in CSV file');
            return;
        }
        
        // Add new participants (avoid duplicates)
        newEmployees.forEach(emp => {
            if (!employees.some(existing => existing.email === emp.email)) {
                employees.push(emp);
            }
        });
        
        updateEmployeeDisplay();
        hideError();
        
        // Show success message
        showSuccess(`Successfully imported ${newEmployees.length} participants from CSV!`);
        
    } catch (error) {
        showError('Error parsing CSV file: ' + error.message);
    }
}

function cancelCSV() {
    csvData = null;
    document.getElementById('csvFile').value = '';
}

function showSuccess(message) {
    // Create a temporary success message
    const successDiv = document.createElement('div');
    successDiv.className = 'success-message';
    successDiv.innerHTML = `<i class="fas fa-check-circle"></i> ${message}`;
    successDiv.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #28a745;
        color: white;
        padding: 15px 20px;
        border-radius: 10px;
        box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        z-index: 1000;
        animation: slideIn 0.3s ease;
    `;
    
    document.body.appendChild(successDiv);
    
    setTimeout(() => {
        successDiv.remove();
    }, 3000);
}



// Utility functions
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Health check function
async function checkAPIHealth() {
    try {
        const response = await fetch(`${API_BASE_URL}/secret_santa/health`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
            mode: 'cors'
        });
        if (!response.ok) {
            console.warn('API Gateway is not responding');
            return false;
        }
        return true;
    } catch (error) {
        console.warn('API Gateway is not available:', error);
        return false;
    }
}

// Check API health on page load
document.addEventListener('DOMContentLoaded', async function() {
    // Delay the health check to allow services to start
    setTimeout(async () => {
        const isHealthy = await checkAPIHealth();
        if (!isHealthy) {
            console.warn('API Gateway health check failed, but continuing...');
        }
    }, 2000);
});
