# Deployment Guide

## 🚀 Portainer Deployment

### Prerequisites

- Portainer installed and running on your server
- Git repository with your code (optional)
- Docker and Docker Compose on the server

### Method 1: Direct Stack Deployment (Recommended)

1. **Copy your project files to the server**

   ```bash
   # On your local machine
   scp -r . user@your-server:/path/to/deployment/

   # Or clone from Git
   git clone https://github.com/your-username/launchpad-manager-backend-go.git
   ```

2. **In Portainer:**
   - Navigate to **Stacks** → **Add stack**
   - Name: `launchpad-backend`
   - Copy the contents of `docker-compose.prod.yml`
   - Set environment variables (optional):
     - `DB_PASSWORD=your_secure_password`
     - `MYSQL_ROOT_PASSWORD=your_secure_root_password`
   - Click **Deploy the stack**

### Method 2: Git Repository Deployment

1. **Push your code to GitHub/GitLab**

2. **In Portainer:**
   - Navigate to **Stacks** → **Add stack**
   - Name: `launchpad-backend`
   - Select **Repository** tab
   - Repository URL: `https://github.com/your-username/launchpad-manager-backend-go.git`
   - Repository reference: `main` (or your branch)
   - Compose path: `docker-compose.prod.yml`
   - Set environment variables
   - Click **Deploy the stack**

### Method 3: Build from Dockerfile

1. **In Portainer:**

   - Go to **Images** → **Build a new image**
   - Upload your project files or use Git repository
   - Image name: `launchpad-backend:latest`
   - Build the image

2. **Create a stack using the built image:**
   ```yaml
   version: "3.8"
   services:
     app:
       image: launchpad-backend:latest
       ports:
         - "8080:8080"
       # ... rest of configuration
   ```

## 🔧 Environment Variables

### Required (with defaults)

- `DB_PASSWORD` - Database password (default: launchpad_password)
- `MYSQL_ROOT_PASSWORD` - MySQL root password (default: root_password)

### Optional

- `GIN_MODE` - Set to `release` for production

## 🌐 Accessing Your Application

After deployment:

- **Application**: `http://your-server-ip:8080`
- **Health Check**: `http://your-server-ip:8080/health`
- **API Base**: `http://your-server-ip:8080/api/v1`

## 🔒 Security Considerations

### Before Production Deployment:

1. **Change default passwords**
2. **Use environment variables for secrets**
3. **Consider using Docker secrets**
4. **Set up a reverse proxy (nginx/traefik)**
5. **Configure SSL/TLS certificates**
6. **Set up firewall rules**

### Example with Reverse Proxy:

```yaml
# Add to your stack
nginx:
  image: nginx:alpine
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
    - ./ssl:/etc/nginx/ssl
  depends_on:
    - app
```

## 📊 Monitoring

### Health Checks

The stack includes health checks for both services:

- App: HTTP health endpoint
- Database: MySQL ping

### Logs

View logs in Portainer:

- Go to **Containers** → Select container → **Logs**

## 🔄 Updates

### Update Application:

1. **Method 1**: Update Git repository and redeploy stack
2. **Method 2**: Rebuild image and redeploy
3. **Method 3**: Update files and restart stack

### Database Migrations:

- Database schema is auto-created from `init.sql`
- For schema changes, consider using migrations

## 🆘 Troubleshooting

### Common Issues:

1. **Port already in use**

   - Change port mapping in docker-compose.yml
   - Check for conflicting services

2. **Database connection failed**

   - Verify environment variables
   - Check database container logs
   - Ensure database is fully started

3. **Build failures**
   - Check Dockerfile syntax
   - Verify all files are present
   - Check network connectivity for dependencies

### Useful Commands:

```bash
# Check container status
docker ps

# View logs
docker logs container_name

# Access container shell
docker exec -it container_name sh

# Check network connectivity
docker network ls
docker network inspect network_name
```

## 📝 Post-Deployment Checklist

- [ ] Application responds to health check
- [ ] API endpoints are accessible
- [ ] Database is connected and working
- [ ] Logs show no errors
- [ ] Environment variables are set correctly
- [ ] Ports are accessible from outside
- [ ] SSL/TLS is configured (if needed)
- [ ] Monitoring is set up
- [ ] Backup strategy is in place
