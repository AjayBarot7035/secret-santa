# UI Service

A modern, animated web interface for the Secret Santa microservices application.

## Features

- **Interactive Employee Management**: Add/remove participants with real-time validation
- **Animated Assignment Generation**: Visual feedback during the assignment process
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Real-time API Integration**: Connects to the API Gateway for backend processing
- **Export Functionality**: Download assignments as CSV
- **Share Results**: Copy results to clipboard or use native sharing
- **Microservices Architecture Display**: Visual representation of the system architecture

## Technologies Used

- **HTML5**: Semantic markup
- **CSS3**: Modern styling with animations and responsive design
- **JavaScript (ES6+)**: Interactive functionality and API communication
- **Nginx**: Web server for static file serving
- **Font Awesome**: Icons
- **Google Fonts**: Typography

## Local Development

### Prerequisites
- Docker and Docker Compose
- All microservices running (API Gateway, Assignment Service, CSV Parser Service)

### Running Locally

1. **Start all microservices**:
   ```bash
   ./start_local_dev.sh
   ```

2. **Open the UI**:
   - Navigate to `http://localhost:8080` in your browser
   - The UI will automatically connect to the API Gateway at `http://localhost:3000`

### Development Mode

For development without Docker:

1. **Serve the UI** (using Python or any static server):
   ```bash
   cd ui-service
   python3 -m http.server 8080
   ```

2. **Update API URL** in `script.js`:
   ```javascript
   const API_BASE_URL = 'http://localhost:3000/api/v1';
   ```

## API Integration

The UI communicates with the following API endpoints:

- `GET /api/v1/secret_santa/health` - Health check
- `POST /api/v1/secret_santa/generate_assignments` - Generate assignments

## File Structure

```
ui-service/
├── index.html          # Main HTML file
├── styles.css          # CSS styles and animations
├── script.js           # JavaScript functionality
├── Dockerfile          # Container configuration
├── nginx.conf          # Nginx configuration
└── README.md           # This file
```

## Animations

The UI includes several animations:

1. **Loading Animation**: Santa hats, gift boxes, and sparkles during assignment generation
2. **Progress Bar**: Visual progress indicator
3. **Success Animation**: Celebration effect when assignments are complete
4. **Hover Effects**: Interactive elements with smooth transitions

## Browser Support

- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## Security

- Content Security Policy headers
- XSS protection
- Frame options protection
- Secure static file serving

## Performance

- Gzip compression enabled
- Static file caching
- Optimized images and fonts
- Minimal JavaScript bundle
