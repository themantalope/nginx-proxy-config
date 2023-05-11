#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

usage() {
    echo "Usage: $0 -s SERVER_NAME -p PORT_NUMBER -n SERVICE_NAME"
    echo "  -s: The server name (domain or IP) for the reverse proxy."
    echo "  -p: The port number on which the proxy will run."
    echo "  -n: The unique name for the service."
    exit 1
}

while getopts ":s:p:n:" opt; do
    case $opt in
        s) server_name="$OPTARG" ;;
        p) port_number="$OPTARG" ;;
        n) service_name="$OPTARG" ;;
        *) usage ;;
    esac
done

if [ -z "$server_name" ] || [ -z "$port_number" ] || [ -z "$service_name" ]; then
    usage
fi

# Create an Nginx reverse proxy configuration
config_file="/etc/nginx/sites-available/reverse-proxy-$service_name.conf"

# Check if the same file already exists
if [ -f "$config_file" ]; then
    echo "Error: Configuration file $config_file already exists. Please specify a unique service name."
    exit 1
fi

cat > $config_file <<EOL
server {
    listen $port_number;
    server_name $server_name;

    location / {
        proxy_pass http://localhost:$port_number;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Create a symlink to the sites-enabled directory
ln -s $config_file /etc/nginx/sites-enabled/

# Reload the systemctl daemon and restart Nginx
systemctl daemon-reload
systemctl restart nginx

echo "Reverse proxy for $service_name on server $server_name on port $port_number has been set up."
