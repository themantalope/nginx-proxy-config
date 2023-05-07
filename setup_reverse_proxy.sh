#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

usage() {
    echo "Usage: $0 -s SERVER_NAME -p PORT_NUMBER"
    echo "  -s: The server name (domain or IP) for the reverse proxy."
    echo "  -p: The port number on which the proxy will run."
    exit 1
}

while getopts ":s:p:" opt; do
    case $opt in
        s) server_name="$OPTARG" ;;
        p) port_number="$OPTARG" ;;
        *) usage ;;
    esac
done

if [ -z "$server_name" ] || [ -z "$port_number" ]; then
    usage
fi

# Create an Nginx reverse proxy configuration
config_file="/etc/nginx/sites-available/reverse-proxy-$server_name.conf"

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

echo "Reverse proxy for $server_name on port $port_number has been set up."
