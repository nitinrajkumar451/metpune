# Metathon Backend

A Rails 8.0.2 API-only application that powers a hackathon evaluation platform. This backend handles document ingestion and AI transcription of various file formats.

## Features

- Document ingestion from Google Drive
- Automatic processing based on file type
- Support for PDF, PPTX, DOCX, JPG, PNG, and ZIP files
- Background processing with Sidekiq
- RESTful API for accessing submissions

## Technology Stack

- Rails 8.0.2 (API-only)
- PostgreSQL
- RSpec with FactoryBot and Faker for testing
- Sidekiq for background jobs
- Google Drive API for document retrieval
- Claude/OpenAI for AI transcription (mocked in tests)

## AI Integration

The application uses AI services for document processing:

- **PDF and DOCX files**: Text extraction with layout preservation
- **PowerPoint presentations**: Slide-by-slide content summarization
- **Images (JPG, PNG)**: OCR text extraction
- **ZIP archives**: Extract and process all contained files based on their types

You can configure either Claude (Anthropic) or OpenAI's API for processing. The system will automatically:

1. Use mock responses in development/test environments (no API keys needed)
2. In production, use the configured AI provider (Claude is preferred if both are configured)

To set up AI processing in production:

1. Add your API key to the environment variables:
   ```
   # For Claude (recommended)
   CLAUDE_API_KEY=your_claude_api_key
   
   # OR for OpenAI
   OPENAI_API_KEY=your_openai_api_key
   ```

2. The system will automatically detect the available provider and use it for processing.

If no API keys are set in production, the application will raise an error during document processing.

## Setup Instructions

### Prerequisites

- Ruby 3.2.0+
- PostgreSQL
- Redis (for Sidekiq)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd metathon_backend
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Configure the database:
   Update `config/database.yml` with your PostgreSQL credentials.

4. Setup the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

5. Configure Google Drive API:
   - Create a Google Cloud project in the [Google Cloud Console](https://console.cloud.google.com/)
   - Enable the Google Drive API for your project
   - Create a Service Account:
     - Go to "IAM & Admin" > "Service Accounts"
     - Click "Create Service Account"
     - Give it a name and description
     - Grant it the "Drive API > Drive API Read Only" role
     - Create and download JSON key
   - Set up credentials in one of these ways:
     - **Environment variables (recommended)**: Copy `.env.example` to `.env` and set:
       ```
       GOOGLE_DRIVE_CREDENTIALS_PATH=/path/to/your/downloaded/credentials.json
       ```
     - **Direct JSON content**: If you can't store the file, set the entire JSON in an environment variable:
       ```
       GOOGLE_DRIVE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"...","private_key_id":"...","private_key":"...","client_email":"...","client_id":"...","auth_uri":"...","token_uri":"...","auth_provider_x509_cert_url":"...","client_x509_cert_url":"..."}
       ```
     - **Rails credentials**: Encrypt the credentials using:
       ```
       rails credentials:edit
       ```
       And add the following structure:
       ```yaml
       google_drive:
         service_account: true
         project_id: your-project-id
         private_key_id: abc123...
         private_key: |
           -----BEGIN PRIVATE KEY-----
           ...
           -----END PRIVATE KEY-----
         client_email: service@project.iam.gserviceaccount.com
         client_id: 123456...
         client_x509_cert_url: https://www.googleapis.com/robot/v1/metadata/x509/service%40project.iam.gserviceaccount.com
       ```
   - Share the "Metathon2025" folder with the service account email (client_email field from the JSON)

6. Start the servers:
   ```bash
   # Start Redis (if not already running)
   redis-server

   # Start Sidekiq
   bundle exec sidekiq

   # Start Rails server
   rails server
   ```

## Running Tests

Run all tests with:
```bash
bundle exec rspec
```

Run specific test types:
```bash
bundle exec rspec spec/models
bundle exec rspec spec/requests
bundle exec rspec spec/services
bundle exec rspec spec/jobs
```

## API Documentation

The API is documented using Swagger (OpenAPI). After starting the server, you can access the API documentation at:

```
http://localhost:3000/api-docs
```

> **Note:** There might be some compatibility issues with Swagger UI and Rails 8. If the Swagger UI is not loading correctly, you can still access the raw OpenAPI specification or use the static HTML guide.

### API Documentation Options

1. **Swagger UI** (if available):
   ```
   http://localhost:3000/api-docs
   ```

2. **Raw OpenAPI Specification**:
   ```
   http://localhost:3000/api-docs/v1/swagger.yaml
   ```
   You can download this file and use it with tools like Postman or Swagger UI Desktop.

3. **Static HTML Guide**:
   ```
   http://localhost:3000/api-guide.html
   ```
   This provides a simple, static HTML documentation of the API endpoints.

## API Endpoints

### POST /api/start_ingestion
Starts the document ingestion process.

**Response:**
```json
{
  "message": "Document ingestion started"
}
```

### GET /api/submissions
Returns a list of all submissions.

**Query Parameters:**
- `status` - Filter by status (pending, processing, success, failed)
- `team_name` - Filter by team name
- `project` - Filter by project

**Response:**
```json
[
  {
    "id": 1,
    "team_name": "Team1",
    "filename": "document.pdf",
    "file_type": "pdf",
    "source_url": "google_drive_file_id",
    "status": "success",
    "project": "Project1",
    "raw_text": "Extracted text content...",
    "created_at": "2025-04-18T09:30:00.000Z",
    "updated_at": "2025-04-18T09:35:00.000Z"
  },
  ...
]
```

### GET /api/submissions/:id
Returns a specific submission.

**Response:**
```json
{
  "id": 1,
  "team_name": "Team1",
  "filename": "document.pdf",
  "file_type": "pdf",
  "source_url": "google_drive_file_id",
  "status": "success",
  "project": "Project1",
  "raw_text": "Extracted text content...",
  "created_at": "2025-04-18T09:30:00.000Z",
  "updated_at": "2025-04-18T09:35:00.000Z"
}
```

## License

MIT
