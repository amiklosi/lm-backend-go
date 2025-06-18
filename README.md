# Launchpad Manager Backend

A Go-based backend service for managing software licenses with MySQL database, containerized with Docker Compose.

## Features

- License validation and registration
- Machine-based license tracking
- RESTful API endpoints
- MySQL database with GORM ORM
- Docker containerization
- Ready for Portainer deployment

## Project Structure

```
launchpad-manager-backend-go/
├── docker-compose.yml    # Docker Compose configuration
├── Dockerfile           # Multi-stage Docker build
├── go.mod              # Go module dependencies
├── go.sum              # Go module checksums
├── main.go             # Main application code
├── init.sql            # Database initialization script
└── README.md           # This file
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
