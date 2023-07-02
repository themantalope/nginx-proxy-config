#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

usage() {
    echo "Usage: $0 [-s SERVER_NAME] [-p PORT_NUMBER] [-f] [-l] [-b] [-e EMAIL]"
    echo "  -s: The server name for the reverse proxy."
    echo "  -p: The port number on which the proxy will run."
    echo "  -h: Display this help message."
    echo "  -f: Force HTTPS redirection."
    echo "  -l: Use Let's Encrypt to generate a certificate."
    echo "  -b: Use basic authentication."
    echo "  -e: Email address for Let's Encrypt."
    exit 1
}

while getopts ":s:p:flbe:h" opt; do
    echo "opt: $opt, OPTARG: $OPTARG"
    case $opt in
        s) server_name="$OPTARG" ;;
        p) port_number="$OPTARG" ;;
        f) force_https=true ;;
        l) use_letsencrypt=true ;;
        b) use_basic_auth=true ;;
        e) email="$OPTARG" ;;
        h) usage ;;
    esac
done



if [ "$use_letsencrypt" = true ] || [ "$use_basic_auth"=true ] || [ "$force_https"=true ]; then
    echo "You have specified that you would like to use services which require HTTPS."
    echo "Automatically setting the -le flag to true."
    use_letsencrypt=true
fi

# print all the arguments to the command line
echo "server_name: $server_name"
echo "port_number: $port_number"
echo "force_https: $force_https"
echo "use_letsencrypt: $use_letsencrypt"
echo "use_basic_auth: $use_basic_auth"
echo "email: $email"

if [ -z "$server_name" ] || [ -z "$port_number" ]; then
    usage
fi


# Create an Nginx reverse proxy configuration
config_file="/etc/nginx/sites-available/reverse-proxy-$server_name.conf"

# redirect_str="return 301 https://\$server_name\$request_uri;"
if [ "$force_https" = true ]; then
    redirect_str="return 301 https://\$server_name\$request_uri;"
else
    redirect_str=""
fi

# ba_str=""
if [ "$use_basic_auth" = true ]; then
    ba_str="auth_basic \"Restricted Content\";
    \tauth_basic_user_file /etc/apache2/.htpasswd;"
else
    ba_str=""
fi

if [ "$use_letsencrypt" = true ] ; then
    cat > $config_file <<EOL
server {
    server_name $server_name;

    location / {
        $ba_str
        proxy_pass http://localhost:$port_number;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
    # create the symlink
    ln -s $config_file /etc/nginx/sites-enabled/
    # Use Let's Encrypt to generate a certificate
    certbot --nginx -d $server_name --non-interactive --agree-tos --email $email
else
    cat > $config_file <<EOL
server {
    server_name $server_name;

    location / {
        $ba_str
        proxy_pass http://localhost:$port_number;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
    # create the symlink
    ln -s $config_file /etc/nginx/sites-enabled/
    # no certbot
fi

# Reload the systemctl daemon and restart Nginx
systemctl daemon-reload
systemctl restart nginx

echo "Reverse proxy for $server_name on port $port_number has been set up."
