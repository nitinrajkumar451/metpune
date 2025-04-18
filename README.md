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
   - Create a Google Cloud project
   - Enable the Google Drive API
   - Create credentials (OAuth 2.0 client ID or service account)
   - Set the environment variables:
     ```
     GOOGLE_DRIVE_CLIENT_ID=your_client_id
     GOOGLE_DRIVE_CLIENT_SECRET=your_client_secret
     ```

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
  "raw_text": "Extracted text content...",
  "created_at": "2025-04-18T09:30:00.000Z",
  "updated_at": "2025-04-18T09:35:00.000Z"
}
```

## License

MIT# metpune
# metpune
# metpune
# metpune
# metpune
