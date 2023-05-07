# Nginx Reverse Proxy Setup Script

This script automates the process of setting up an Nginx reverse proxy. It creates a new Nginx configuration file, sets up a symlink to the `sites-enabled` directory, and restarts the Nginx service.

## Prerequisites

- Nginx installed on your system. If you haven't installed it yet, you can do so by running:

```bash
sudo apt update
sudo apt install nginx
```

## Usage

1. Save the `setup_reverse_proxy.sh` script to your desired directory.

2. Navigate to the directory containing the script and give it execute permissions:

```bash
chmod +x setup_reverse_proxy.sh
```

3. Run the script as root, providing the server name and port number as command-line arguments:

```bash
sudo ./setup_reverse_proxy.sh -s example.com -p 8000
```

Replace `example.com` with your server name (domain or IP address) and `8000` with your desired port number.

4. The script will create a new Nginx configuration file in the `/etc/nginx/sites-available` directory, set up a symlink to the `sites-enabled` directory, and restart the Nginx service.

5. Your reverse proxy should now be up and running, forwarding requests to the specified server name and port number.

## Help

If you need help with the script usage or want to see the available command-line options, run the script without any arguments or with the `-h` flag:

```bash
./setup_reverse_proxy.sh
./setup_reverse_proxy.sh -h
```
