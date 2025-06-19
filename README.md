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

