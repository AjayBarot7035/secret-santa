// Global variables
let employees = [];
let assignments = [];
let isGenerating = false;

// API Configuration
const API_BASE_URL = 'http://localhost:3000/api/v1'\;

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
    
    // Load sample data for demo
    loadSampleData();
});

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
        showError('An employee with this email already exists');
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
    
    employeeList.innerHTML = employees.map(emp => `
        <div class="employee-card">
            <div class="employee-info">
                <h4>${emp.name}</h4>
                <p>${emp.email}</p>
            </div>
            <button class="remove-btn" onclick="removeEmployee('${emp.email}')">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `).join('');
    
    // Update generate button state
    generateBtn.disabled = employees.length < 2;
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
            body: JSON.stringify({ employees })
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

// Simulate microservices processing with animations
async function simulateMicroservicesProcess() {
    const steps = [
        { progress: 20, status: 'Parsing employee data...' },
        { progress: 40, status: 'Validating assignments...' },
        { progress: 60, status: 'Generating Secret Santa pairs...' },
        { progress: 80, status: 'Finalizing assignments...' },
        { progress: 100, status: 'Assignments complete!' }
    ];
    
    for (let i = 0; i < steps.length; i++) {
        await new Promise(resolve => setTimeout(resolve, 800));
        updateProgress(steps[i].progress, steps[i].status);
    }
}

// Update progress bar and status
function updateProgress(progress, status) {
    progressFill.style.width = `${progress}%`;
    statusText.textContent = status;
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
    updateEmployeeDisplay();
    hideError();
    resultsSection.style.display = 'none';
    animationSection.style.display = 'none';
    employeeNameInput.focus();
}

// Export to CSV
function exportToCSV() {
    if (assignments.length === 0) {
        showError('No assignments to export');
        return;
    }
    
    const csvContent = [
        'Santa Name,Santa Email,Secret Child Name,Secret Child Email',
        ...assignments.map(assignment => 
            `${assignment.santa_name},${assignment.santa_email},${assignment.secret_child_name},${assignment.secret_child_email}`
        )
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

// Utility functions
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Health check function
async function checkAPIHealth() {
    try {
        const response = await fetch(`${API_BASE_URL}/secret_santa/health`);
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
    const isHealthy = await checkAPIHealth();
    if (!isHealthy) {
        showError('API Gateway is not available. Please ensure all microservices are running.');
    }
});
