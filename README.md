# Metathon Backend

A Rails 8.0.2 API-only application that powers a hackathon evaluation platform. This backend handles document ingestion, AI transcription of various file formats, team summarization, and AI-powered evaluation.

## Features

- Document ingestion from Google Drive
- Automatic processing based on file type
- Support for PDF, PPTX, DOCX, JPG, PNG, and ZIP files
- Background processing with Sidekiq
- RESTful API for accessing submissions
- Team summarization across multiple documents
- AI-powered team evaluation with customizable judging criteria
- Leaderboard generation with team rankings
- Blog post generation from team summaries

## Technology Stack

- Rails 8.0.2 (API-only)
- PostgreSQL
- RSpec with FactoryBot and Faker for testing
- Sidekiq for background jobs
- Google Drive API for document retrieval
- Claude/OpenAI for AI transcription (mocked in tests)

## AI Integration

The application uses AI services for document processing, summarization, evaluation, and content generation:

### Document Processing

- **PDF and DOCX files**: Text extraction with layout preservation
- **PowerPoint presentations**: Slide-by-slide content summarization
- **Images (JPG, PNG)**: OCR text extraction
- **ZIP archives**: Extract and process all contained files based on their types

### AI Summarization

- **Individual files**: Generates concise summaries based on extracted content
- **Team summaries**: Creates comprehensive reports that analyze all team submissions
  - Product objectives
  - Key achievements
  - Challenges encountered
  - Innovative approaches
  - Technical highlights
  - Recommendations

### AI Evaluation

- **Custom judging criteria**: Configure evaluation criteria with weightage
- **Objective assessment**: AI evaluates team submissions against criteria
- **Detailed feedback**: Provides specific feedback for each criterion
- **Weighted scoring**: Calculates total score based on criteria importance

### AI Blog Generation

- **Technical blog posts**: Creates structured, engaging content from team summaries
- **Markdown format**: Properly formatted with frontmatter and sections
- **Storytelling**: Crafts a narrative around the team's journey and project
- **Technical details**: Highlights key technical aspects and learning moments

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

### Submissions

#### POST /api/start_ingestion
Starts the document ingestion process.

**Response:**
```json
{
  "message": "Document ingestion started"
}
```

#### GET /api/submissions
Returns a list of all submissions.

**Query Parameters:**
- `status` - Filter by status (pending, processing, success, failed)
- `team_name` - Filter by team name
- `project` - Filter by project
- `summaries_only` - Set to 'true' to get only summary fields

**Response:**
```json
{
  "submissions": [
    {
      "id": 1,
      "team_name": "Team1",
      "filename": "document.pdf",
      "file_type": "pdf",
      "source_url": "google_drive_file_id",
      "status": "success",
      "project": "Project1",
      "raw_text": "Extracted text content...",
      "summary": "Concise summary of the document...",
      "created_at": "2025-04-18T09:30:00.000Z",
      "updated_at": "2025-04-18T09:35:00.000Z"
    },
    ...
  ]
}
```

#### GET /api/submissions/:id
Returns a specific submission.

**Response:**
```json
{
  "submission": {
    "id": 1,
    "team_name": "Team1",
    "filename": "document.pdf",
    "file_type": "pdf",
    "source_url": "google_drive_file_id",
    "status": "success",
    "project": "Project1",
    "raw_text": "Extracted text content...",
    "summary": "Concise summary of the document...",
    "created_at": "2025-04-18T09:30:00.000Z",
    "updated_at": "2025-04-18T09:35:00.000Z"
  }
}
```

#### GET /api/summaries
Returns summaries organized by team and project.

**Response:**
```json
{
  "Team1": {
    "Project1": [
      {
        "id": 1,
        "filename": "document.pdf",
        "file_type": "pdf",
        "summary": "Document summary...",
        "created_at": "2025-04-18T09:30:00.000Z"
      },
      ...
    ],
    "Project2": [
      ...
    ]
  },
  "Team2": {
    ...
  }
}
```

### Team Summaries

#### GET /api/team_summaries
Returns all team summaries.

**Query Parameters:**
- `status` - Filter by status (pending, processing, success, failed)

**Response:**
```json
{
  "team_summaries": [
    {
      "id": 1,
      "team_name": "Team1",
      "content": "# Team Report\n\n## PRODUCT OBJECTIVE\n...",
      "status": "success",
      "created_at": "2025-04-18T10:30:00.000Z",
      "updated_at": "2025-04-18T10:35:00.000Z"
    },
    ...
  ]
}
```

#### GET /api/team_summaries/:team_name
Returns a specific team summary.

**Response:**
```json
{
  "team_summary": {
    "id": 1,
    "team_name": "Team1",
    "content": "# Team Report\n\n## PRODUCT OBJECTIVE\n...",
    "status": "success",
    "created_at": "2025-04-18T10:30:00.000Z",
    "updated_at": "2025-04-18T10:35:00.000Z"
  }
}
```

#### POST /api/team_summaries/generate
Generates a new team summary.

**Request:**
```json
{
  "team_name": "Team1"
}
```

**Response:**
```json
{
  "message": "Team summary generation started for: Team1"
}
```

### Judging Criteria

#### GET /api/judging_criteria
Returns all judging criteria.

**Response:**
```json
{
  "judging_criteria": [
    {
      "id": 1,
      "name": "Innovation",
      "description": "How innovative is the solution?",
      "weight": 3.0,
      "created_at": "2025-04-18T11:30:00.000Z",
      "updated_at": "2025-04-18T11:30:00.000Z"
    },
    ...
  ]
}
```

#### POST /api/judging_criteria
Creates a new judging criterion.

**Request:**
```json
{
  "judging_criterion": {
    "name": "User Experience",
    "description": "How intuitive and user-friendly is the solution?",
    "weight": 3.5
  }
}
```

**Response:**
```json
{
  "judging_criterion": {
    "id": 6,
    "name": "User Experience",
    "description": "How intuitive and user-friendly is the solution?",
    "weight": 3.5,
    "created_at": "2025-04-18T12:30:00.000Z",
    "updated_at": "2025-04-18T12:30:00.000Z"
  }
}
```

### Team Evaluations

#### GET /api/team_evaluations
Returns all team evaluations.

**Query Parameters:**
- `status` - Filter by status (pending, processing, success, failed)
- `sort_by` - Set to 'score' to sort by total score

**Response:**
```json
{
  "team_evaluations": [
    {
      "id": 1,
      "team_name": "Team1",
      "scores": {
        "Innovation": {
          "score": 4.2,
          "weight": 3.0,
          "feedback": "The team demonstrated excellent innovation..."
        },
        "Technical Execution": {
          "score": 4.5,
          "weight": 4.0,
          "feedback": "The technical implementation is robust..."
        },
        ...
      },
      "total_score": 4.35,
      "comments": "Overall, this is a strong project with impressive technical implementation...",
      "status": "success",
      "created_at": "2025-04-18T13:30:00.000Z",
      "updated_at": "2025-04-18T13:35:00.000Z"
    },
    ...
  ]
}
```

#### GET /api/team_evaluations/:team_name
Returns a specific team evaluation.

**Response:**
```json
{
  "team_evaluation": {
    "id": 1,
    "team_name": "Team1",
    "scores": {
      "Innovation": {
        "score": 4.2,
        "weight": 3.0,
        "feedback": "The team demonstrated excellent innovation..."
      },
      ...
    },
    "total_score": 4.35,
    "comments": "Overall, this is a strong project with impressive technical implementation...",
    "status": "success",
    "created_at": "2025-04-18T13:30:00.000Z",
    "updated_at": "2025-04-18T13:35:00.000Z"
  }
}
```

#### POST /api/team_evaluations/generate
Generates a new team evaluation.

**Request:**
```json
{
  "team_name": "Team1",
  "criteria_ids": [1, 2, 3, 4, 5]
}
```

**Response:**
```json
{
  "message": "Team evaluation started for: Team1"
}
```

#### GET /api/leaderboard
Returns a ranked leaderboard of all evaluated teams.

**Response:**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "team_name": "Team2",
      "total_score": 4.7,
      "scores": {
        "Innovation": {"score": 4.8, "weight": 3.0},
        "Technical Execution": {"score": 4.9, "weight": 4.0},
        ...
      }
    },
    {
      "rank": 2,
      "team_name": "Team1",
      "total_score": 4.35,
      "scores": {
        "Innovation": {"score": 4.2, "weight": 3.0},
        "Technical Execution": {"score": 4.5, "weight": 4.0},
        ...
      }
    },
    ...
  ]
}
```

### Team Blogs

#### GET /api/team_blogs
Returns all team blogs.

**Query Parameters:**
- `status` - Filter by status (pending, processing, success, failed)

**Response:**
```json
{
  "team_blogs": [
    {
      "id": 1,
      "team_name": "Team1",
      "content": "---\ntitle: \"Innovating Document Analysis: Team1's Hackathon Journey\"\nauthor: \"Team1\"\ndate: \"2025-04-18\"\ntags: [\"hackathon\", \"AI\", \"document-processing\"]\n---\n\n# Innovating Document Analysis...",
      "status": "success",
      "created_at": "2025-04-18T14:30:00.000Z",
      "updated_at": "2025-04-18T14:35:00.000Z"
    },
    ...
  ]
}
```

#### GET /api/team_blogs/:team_name
Returns a specific team blog.

**Response:**
```json
{
  "team_blog": {
    "id": 1,
    "team_name": "Team1",
    "content": "---\ntitle: \"Innovating Document Analysis: Team1's Hackathon Journey\"\nauthor: \"Team1\"\ndate: \"2025-04-18\"\ntags: [\"hackathon\", \"AI\", \"document-processing\"]\n---\n\n# Innovating Document Analysis...",
    "status": "success",
    "created_at": "2025-04-18T14:30:00.000Z",
    "updated_at": "2025-04-18T14:35:00.000Z"
  }
}
```

#### GET /api/team_blogs/:team_name/markdown
Returns the raw markdown content of a team blog for direct rendering.

**Response:**
```markdown
---
title: "Innovating Document Analysis: Team1's Hackathon Journey"
author: "Team1"
date: "2025-04-18"
tags: ["hackathon", "AI", "document-processing"]
---

# Innovating Document Analysis: Team1's Hackathon Journey

## Introduction

In the fast-paced world of document management and analysis...
```

#### POST /api/team_blogs/generate
Generates a new team blog from a team summary.

**Request:**
```json
{
  "team_name": "Team1"
}
```

**Response:**
```json
{
  "message": "Team blog generation started for: Team1"
}
```

## License

MIT
