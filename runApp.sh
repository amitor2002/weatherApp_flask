echo "Setting directory permissions..."
chmod -R 755 /weatherApp
chown -R www-data:www-data /weatherApp

echo "Starting Nginx..."
nginx -g "daemon off;" &

echo "Starting Gunicorn..."

# Define socket path and user/group settings (set to www-data for Docker)
SOCKET_PATH="/weatherApp/weatherApp.sock"

# If the socket already exists, remove it
if [ -e "$SOCKET_PATH" ]; then
    rm "$SOCKET_PATH"
fi

# Start Gunicorn with the socket binding
umask 002 && /weatherApp/venv/bin/gunicorn --workers=3 --bind unix:$SOCKET_PATH wsgi:app &

# Set the correct permissions for the Unix socket
chown www-data:www-data "$SOCKET_PATH"
chmod 660 "$SOCKET_PATH"
