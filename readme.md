# Flask Application Deployment with Nginx and Gunicorn

This comprehensive guide provides step-by-step instructions to deploy a Flask web application in a production environment using Nginx as a reverse proxy and Gunicorn as the WSGI server.

## Prerequisites

- **Ubuntu/Debian** based server (though instructions can be adapted for other Linux distributions)
- **Python 3.8+** installed on your server
- **Root or sudo** access to the server
- **Domain name** (optional, but recommended for production)

## Step 1: Update System and Install Core Dependencies

```bash
# Update package lists and upgrade existing packages
sudo apt update
sudo apt upgrade -y

# Install required system packages
sudo apt install -y python3 python3-pip python3-venv nginx
```

## Step 2: Set Up Project Directory and Virtual Environment

```bash
# Create a directory for your application
sudo mkdir -p /var/www/weatherapp
sudo chown $USER:$USER /var/www/weatherapp

# Navigate to project directory
cd /var/www/weatherapp

# Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip
```

## Step 3: Install Flask and Dependencies

Create a `requirements.txt` file with your application's dependencies:

```
Flask==2.3.3
gunicorn==21.2.0
```

Install the dependencies:

```bash
pip install -r requirements.txt
```

## Step 4: Configure Gunicorn

Create a WSGI entry point file named `wsgi.py` in your project directory:

```python
from app import app

if __name__ == "__main__":
    app.run()
```

## Step 5: Create the runApp.sh Script

Create a script that will start Gunicorn and manage the socket file:

```bash
#!/bin/bash

echo "starting nginx..."
sudo systemctl start nginx

echo "starting Gunicorn..."
cd /home/amit/git/amit.orenshtein/python/deployment_weatherApp || exit

SOCKET_PATH="/var/www/weatherapp/weatherApp.sock"
SOCKET_GROUP="www-data"

if [ -e "$SOCKET_PATH" ]; then
    rm "$SOCKET_PATH"
fi

sg $SOCKET_GROUP -c "umask 002 && /home/amit/git/amit.orenshtein/python/deployment_weatherApp/venv/bin/gunicorn --workers=3 --bind unix:$SOCKET_PATH wsgi:app"

sudo chown $USER:$SOCKET_GROUP "$SOCKET_PATH"
sudo chmod 660 "$SOCKET_PATH"

```

Make the script executable:

```bash
chmod +x /var/www/weatherapp/runApp.sh
```

## Step 6: Configure Nginx as Reverse Proxy

Create an Nginx server block configuration:

```bash
sudo nano /etc/nginx/sites-available/weatherapp.conf
```

Add the following content:

```nginx
server {
    listen 9090;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/weatherapp/weatherApp.sock;
    }

    error_log /var/log/nginx/weatherapp_error.log;
    access_log /var/log/nginx/weatherapp_access.log;
}
```

Create the proxy_params file if it doesn't exist:

```bash
sudo nano /etc/nginx/proxy_params
```

Add the following content:

```
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

Enable the Nginx configuration:

```bash
sudo ln -s /etc/nginx/sites-available/weatherapp.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default  # Remove default config if needed
```

Test the Nginx configuration and restart:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

## Step 7: Set Correct Permissions

Ensure proper permissions for the application:

```bash
# Create a dedicated group for Nginx and your application
sudo groupadd webapps
sudo usermod -a -G webapps www-data
sudo usermod -a -G webapps $USER

# Set permissions
sudo chown -R $USER:webapps /var/www/weatherapp
sudo chmod -R 750 /var/www/weatherapp
sudo chmod g+s /var/www/weatherapp

# Ensure Nginx can access the socket
touch /var/www/weatherapp/weatherApp.sock
sudo chown www-data:webapps /var/www/weatherapp/weatherApp.sock
sudo chmod 660 /var/www/weatherapp/weatherApp.sock
```

## Step 8: Running the Application

To start your application, simply run:

```bash
cd /var/www/weatherapp
./runApp.sh
```

## Step 9: Security Considerations

### Firewall Configuration

Configure your firewall to allow HTTP/HTTPS traffic:

```bash
sudo apt install -y ufw
sudo ufw allow 9090/tcp
sudo ufw allow ssh  # Don't lock yourself out
sudo ufw enable
sudo ufw status
```

## Appendix: Sample Application Structure

```
/var/www/weatherapp/
├── app.py               # Your Flask application
├── runApp.sh            # Script to run nginx and gunicorn
├── wsgi.py              # WSGI entry point
├── requirements.txt     # Python dependencies
├── venv/                # Virtual environment
├── templates/           # Template files
├── weatherApp.sock      # the socket that created when the script's running

```

---

Happy deploying!
