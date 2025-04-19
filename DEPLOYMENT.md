# Metathon Backend Deployment Guide

This guide provides detailed instructions for deploying the Metathon Backend application to a production environment. Follow these steps to ensure a successful deployment.

## Pre-Deployment Checklist

- [x] Error handling system implemented
- [x] GoogleDriveService export detection fixed
- [x] All tests are passing
- [x] API documentation updated for all endpoints
- [x] Sidekiq properly configured
- [x] Deployment documentation created

## Environment Variables

Configure the following environment variables in your production environment:

### Core Configuration
```
# Rails environment
RAILS_ENV=production

# Rails master key (for credentials)
RAILS_MASTER_KEY=your_master_key_here

# Database connection
DATABASE_URL=postgres://username:password@hostname/database_name

# Redis connection for Sidekiq
REDIS_URL=redis://hostname:6379/0
```

### AI Provider Configuration
```
# Choose one or both (Claude is preferred if both are provided)
CLAUDE_API_KEY=your_claude_api_key
OPENAI_API_KEY=your_openai_api_key
```

### Google Drive Configuration
```
# Method 1: Service account JSON file path
GOOGLE_DRIVE_CREDENTIALS_PATH=/path/to/credentials.json

# Method 2: Service account JSON content
GOOGLE_DRIVE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"...","private_key_id":"...","private_key":"...","client_email":"...","client_id":"...","auth_uri":"...","token_uri":"...","auth_provider_x509_cert_url":"...","client_x509_cert_url":"..."}
```

### Sidekiq Configuration
```
# Redis pool size
REDIS_POOL_SIZE=25

# Sidekiq concurrency
SIDEKIQ_CONCURRENCY=25

# Sidekiq admin UI credentials
SIDEKIQ_USERNAME=admin
SIDEKIQ_PASSWORD=secure_password
```

### Error Reporting
```
# Sentry configuration
SENTRY_DSN=https://your-sentry-key@sentry.io/project
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1
```

## Database Setup

1. Create the production database:
   ```bash
   RAILS_ENV=production rails db:create
   ```

2. Run migrations:
   ```bash
   RAILS_ENV=production rails db:migrate
   ```

3. (Optional) Seed initial data:
   ```bash
   RAILS_ENV=production rails db:seed
   ```

## Starting the Application

### Option 1: Using Foreman

With Foreman, you can start both the web server and Sidekiq workers using the provided Procfile:

```bash
foreman start
```

### Option 2: Manual Startup

Start each process individually:

1. Rails server:
   ```bash
   RAILS_ENV=production rails server -p 3000 -b 0.0.0.0
   ```

2. Sidekiq worker:
   ```bash
   RAILS_ENV=production bundle exec sidekiq -C config/sidekiq.yml
   ```

### Option 3: Docker Deployment

1. Build the Docker image:
   ```bash
   docker build -t metathon-backend .
   ```

2. Run the container:
   ```bash
   docker run -p 3000:3000 --env-file .env metathon-backend
   ```

## Monitoring and Maintenance

### Health Checks

The application provides the following health endpoints:

- `/health`: Basic application health check
- `/health/db`: Database connection check
- `/health/redis`: Redis connection check
- `/health/sidekiq`: Sidekiq process status

### Log Monitoring

Application logs are output to:

- `STDOUT` for containerized deployments
- `log/production.log` for traditional deployments

### Sidekiq Monitoring

The Sidekiq dashboard is available at:

```
https://your-app-domain/sidekiq
```

Access requires the SIDEKIQ_USERNAME and SIDEKIQ_PASSWORD credentials.

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Verify DATABASE_URL is correctly formatted
   - Check that the database server is accessible from the application server
   - Ensure database user has correct permissions

2. **Redis Connection Issues**
   - Verify REDIS_URL is correctly formatted
   - Check that Redis server is running and accessible
   - Check network connectivity between application and Redis

3. **AI Processing Issues**
   - Verify AI provider keys are correctly set
   - Check API rate limits
   - Monitor job failures in Sidekiq dashboard

4. **Google Drive Connection Issues**
   - Verify credentials are correctly set
   - Check that service account has access to the documents
   - Verify folder structure matches expected pattern

## Backup Strategy

1. **Database Backup**
   - Set up regular PostgreSQL dumps
   - Store backups securely offsite
   - Test restoration procedure regularly

2. **Configuration Backup**
   - Backup all environment variables
   - Backup credentials and keys
   - Document recovery procedures

## Scaling Considerations

For higher workloads:

1. **Horizontal Scaling**
   - Add multiple web server instances
   - Ensure sessions are shared across instances if applicable
   - Use a load balancer for distribution

2. **Sidekiq Scaling**
   - Increase Sidekiq concurrency for more parallel jobs
   - Add dedicated Sidekiq workers for specific queues
   - Monitor memory usage and adjust as needed

3. **Database Scaling**
   - Add read replicas for scaling read operations
   - Consider connection pooling
   - Monitor query performance and add indexes as needed