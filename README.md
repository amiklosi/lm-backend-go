# Launchpad Manager Backend

A Go-based backend service for managing software licenses with MySQL database, containerized with Docker Compose.

## Features

- License validation and registration
- Machine-based license tracking
- RESTful API endpoints
- MySQL database with GORM ORM
- Docker containerization
- Ready for Portainer deployment
- **CI/CD with GitHub Actions**

## Project Structure

```
launchpad-manager-backend-go/
├── .github/workflows/build.yml  # GitHub Actions CI/CD pipeline
├── docker-compose.yml           # Docker Compose configuration
├── docker-compose.prod.ci.yml   # Production compose for CI/CD
├── Dockerfile                   # Multi-stage Docker build
├── Dockerfile.mysql             # MySQL image with init script
├── go.mod                      # Go module dependencies
├── go.sum                      # Go module checksums
├── main.go                     # Main application code
├── init.sql                    # Database initialization script
├── env.example                 # Environment variables template
└── README.md                   # This file
```

## Database Schema

### Licenses Table

- `id`: Primary key, auto-increment
- `email`: Customer email address
- `licensekey`: Unique license key
- `remaining`: Number of remaining machine activations (default: 5)
- `purchaseinfo`: Additional purchase information
- `purchasedate`: Timestamp of purchase

### Users Table

- `uid`: Primary key, auto-increment
- `key_id`: Foreign key to licenses table
- `machine_id`: Unique machine identifier
- `created`: Timestamp of machine registration

## API Endpoints

### Base URL

```
http://localhost:8080/api/v1
```

### 1. Validate License

**POST** `/validate`

Validates a license key and registers a machine if valid.

**Request Body:**

```json
{
  "licensekey": "LP-1234567890-1234",
  "machine_id": "machine-123"
}
```

**Response:**

```json
{
  "valid": true,
  "message": "License is valid and machine registered"
}
```

### 2. Register License

**POST** `/register`

Creates a new license for an email address.

**Request Body:**

```json
{
  "email": "user@example.com"
}
```

**Response:**

```json
{
  "success": true,
  "licensekey": "LP-1234567890-1234",
  "message": "License created successfully"
}
```

### 3. Health Check

**GET** `/health`

Returns service health status.

**Response:**

```json
{
  "status": "healthy"
}
```

## Quick Start

### Prerequisites

- Docker
- Docker Compose

### Running the Application

1. **Clone and navigate to the project:**

   ```bash
   cd launchpad-manager-backend-go
   ```

2. **Start the services:**

   ```bash
   docker-compose up -d
   ```

3. **Check if services are running:**

   ```bash
   docker-compose ps
   ```

4. **View logs:**
   ```bash
   docker-compose logs -f app
   ```

### Testing the API

1. **Register a new license:**

   ```bash
   curl -X POST http://localhost:8080/api/v1/register \
     -H "Content-Type: application/json" \
     -d '{"email": "test@example.com"}'
   ```

2. **Validate a license:**

   ```bash
   curl -X POST http://localhost:8080/api/v1/validate \
     -H "Content-Type: application/json" \
     -d '{"licensekey": "LP-1234567890-1234", "machine_id": "machine-123"}'
   ```

3. **Check health:**
   ```bash
   curl http://localhost:8080/health
   ```

## Environment Variables

The application uses the following environment variables (configured in docker-compose.yml):

- `DB_HOST`: Database host (default: db)
- `DB_PORT`: Database port (default: 3306)
- `DB_USER`: Database username (default: launchpad_user)
- `DB_PASSWORD`: Database password (default: launchpad_password)
- `DB_NAME`: Database name (default: launchpad_db)
- `PORT`: Application port (default: 8080)

## Portainer Deployment

This stack is ready for Portainer deployment. Simply:

1. Copy the `docker-compose.yml` file content
2. Create a new stack in Portainer
3. Paste the compose content
4. Deploy the stack

The application will be available on port 8080 of your host machine.

## CI/CD with GitHub Actions

This project includes a complete CI/CD pipeline using GitHub Actions that automatically builds and pushes Docker images to GitHub Container Registry.

### Pipeline Overview

The CI/CD pipeline builds and pushes two Docker images:

1. **Main Application**: `ghcr.io/your-username/launchpad-manager-backend-go`
2. **MySQL Database**: `ghcr.io/your-username/launchpad-manager-backend-go-mysql`

### Setup Instructions

#### 1. Repository Setup

1. **Push your code to GitHub:**

   ```bash
   git add .
   git commit -m "Add CI/CD pipeline"
   git push origin main
   ```

2. **Enable GitHub Actions:**
   - Go to your repository on GitHub
   - Navigate to Settings → Actions → General
   - Ensure "Allow all actions and reusable workflows" is selected

#### 2. Container Registry Access

The pipeline automatically uses GitHub Container Registry (ghcr.io). No additional configuration needed - it uses the built-in `GITHUB_TOKEN`.

### Pipeline Details

#### Build Job

- Runs on Ubuntu latest
- Sets up Docker Buildx for efficient builds
- Logs in to GitHub Container Registry
- Builds both app and MySQL images
- Pushes images with multiple tags:
  - `latest` (only on main branch)
  - `main` (branch name)
  - `sha-{commit-hash}` (commit-specific)
- Uses GitHub Actions cache for faster builds

#### Image Tags

The pipeline creates the following tags:

- `latest`: Latest version from main branch
- `main`: Current main branch
- `main-{sha}`: Specific commit on main branch
- `pr-{number}`: Pull request builds (not pushed to registry)

### Production Deployment

To deploy using the built images:

1. **Set up environment variables:**

   ```bash
   cp env.example .env
   # Edit .env with your values
   ```

2. **Deploy with production compose:**

   ```bash
   docker-compose -f docker-compose.prod.ci.yml up -d
   ```

### Environment Variables for Production

Set these environment variables in your `.env` file:

```bash
# GitHub Repository (replace with your actual repository)
GITHUB_REPOSITORY=your-username/launchpad-manager-backend-go

# Database Configuration
DB_PASSWORD=your_secure_password_here
MYSQL_ROOT_PASSWORD=your_secure_root_password_here
```

### Manual Image Building

If you need to build images manually:

```bash
# Build and push main application
docker build -t ghcr.io/your-username/launchpad-manager-backend-go:latest .
docker push ghcr.io/your-username/launchpad-manager-backend-go:latest

# Build and push MySQL image
docker build -f Dockerfile.mysql -t ghcr.io/your-username/launchpad-manager-backend-go-mysql:latest .
docker push ghcr.io/your-username/launchpad-manager-backend-go-mysql:latest
```

### Monitoring the Pipeline

- View pipeline runs in the "Actions" tab of your GitHub repository
- Check build logs for any issues
- Monitor image pushes in the "Packages" tab

### Troubleshooting CI/CD

#### Common Issues

1. **Build failures:**

   - Check Dockerfile syntax
   - Verify all dependencies are in go.mod
   - Ensure Docker context is correct

2. **Push failures:**

   - Check repository permissions
   - Verify GITHUB_TOKEN has package write access
   - Ensure repository name matches exactly

3. **Cache issues:**
   - Clear GitHub Actions cache if builds are slow
   - Check cache hit rates in build logs

## Development

### Local Development Setup

1. **Install Go dependencies:**

   ```bash
   go mod download
   ```

2. **Run the application locally:**

   ```bash
   go run main.go
   ```

3. **Run tests (if any):**
   ```bash
   go test ./...
   ```

### Building the Docker Image

```bash
docker build -t launchpad-manager-backend .
```

## License Management Logic

- Each license can be used on up to 5 machines by default
- When a machine validates a license for the first time, it gets registered
- Subsequent validations from the same machine are always valid
- The `remaining` count decreases when new machines are registered
- License keys are generated with a timestamp-based format

## Security Considerations

- In production, implement proper authentication and authorization
- Use HTTPS for all API communications
- Implement rate limiting
- Use more secure license key generation
- Add input validation and sanitization
- Consider implementing API keys for access control

## Troubleshooting

### Common Issues

1. **Database connection failed:**

   - Ensure MySQL container is running: `docker-compose ps`
   - Check database logs: `docker-compose logs db`

2. **Port already in use:**

   - Change the port mapping in `docker-compose.yml`
   - Or stop other services using port 8080

3. **Permission issues:**
   - Ensure Docker has proper permissions
   - Run with `sudo` if necessary (Linux/macOS)

### Logs

View application logs:

```bash
docker-compose logs -f app
```

View database logs:

```bash
docker-compose logs -f db
```
