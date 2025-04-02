<div style="background-color: #d2b48c; padding: 20px; border-radius: 5px;">

# Docker Compose Setup: Gunicorn + Nginx

A production-ready Docker Compose configuration for running Python web applications with Gunicorn as the WSGI server behind an Nginx reverse proxy with load balancing.

## Overview

This project demonstrates how to:

- Use multi-stage Docker builds to optimize container size
- Configure Gunicorn to serve Python web applications
- Set up Nginx as a reverse proxy with load balancing
- Orchestrate multiple services with Docker Compose

## Architecture

```
                    ┌─────────────┐
                    │             │
 Client Request ───►│    Nginx    │──┬──► Gunicorn Instance 1
                    │Load Balancer│  │
                    │             │  └──► Gunicorn Instance 2
                    └─────────────┘
```

## Prerequisites

- Docker (v20.10 or later)
- Docker Compose (v1.29 or later)

## Project Structure

```
.
├── app/
│ └── app.py
│  └── requirements.txt
│  └── wsgi.py
│  ├── services
│    └── weather_service.py
│  ├── templates
│    └── index.html
├── docker-compose.yml
├── dockerfile.gunicornApp
├── dockerfile.nginx
├── entrypoint.sh
└── weatherApp_nginx.conf
```

## Configuration Files

### 1. Gunicorn Dockerfile (`dockerfile.gunicornApp`)

```dockerfile
# Stage 1: Build stage
FROM python:3.13-slim AS build
ENV PYTHONUNBUFFERED=1
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/. .

# Stage 2: Runtime stage
FROM python:3.13-slim AS runtime
WORKDIR /app
COPY --from=build /app /app

ENTRYPOINT ["gunicorn", "-b", "0.0.0.0:8000", "-w", "3", "wsgi:app"]

```

### 2. Nginx Dockerfile (`dockerfile.nginx`)

```dockerfile
FROM nginx:latest

RUN rm /etc/nginx/conf.d/default.conf
COPY weatherApp_nginx.conf /etc/nginx/conf.d/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 3. Build both images (Nginx and Gunicorn)

```
docker build -t gunicorn-app -f dockerfile.gunicornApp .
docker build -t nginx-image -f dockerfile.nginx .
```

### 3. Docker Compose File (`docker-compose.yml`)

```yaml
services:
  gunicorn1:
    image: gunicorn-app
    deploy:
      replicas: 2
    expose:
      - "8000"
    restart: always
    networks:
      - weather-network

  gunicorn2:
    image: gunicorn-app
    expose:
      - "8000"
    restart: always
    networks:
      - weather-network

  nginx:
    image: nginx-image
    ports:
      - "80:80"
    depends_on:
      - gunicorn1
      - gunicorn2
    restart: always
    networks:
      - weather-network

networks:
  weather-network:
    driver: bridge
```

### 4. Nginx Configuration (`weatherApp_nginx.conf`)

```nginx
upstream gunicorn {
    server gunicorn1:8000;
    server gunicorn2:8000;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://gunicorn;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Usage

### Starting the Application

```bash
docker compose up
```

This command starts the containers as defined in the `docker-compose.yml` file.

### Accessing the Application

Once the containers are running, access the application at:

- http://localhost

Nginx will load balance requests between the two Gunicorn instances.

### Stopping the Application

To stop and remove the containers:

```bash
docker compose down
```

</div>
