#!/bin/bash
if [ -z "$1" ] && [ -z "$public_ip" ]; then
    echo "Please input domain or public IP of your VPS:"
    read public_ip
elif [ -z "$public_ip" ]; then
    public_ip=$1
fi
working_folder=$(pwd)
folder_name=${PWD##*/}
if [ -z "$public_ip" ]; then
    echo "Public IP should not be empty!"
    exit
fi
echo $working_folder
echo $folder_name
sudo cat <<EOF > /etc/nginx/sites-available/$folder_name
server {
    listen 80;
    server_name $public_ip;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root $working_folder;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$working_folder/$folder_name.mock;
    }
}
EOF
sudo cat <<EOF >> local_settings.py
DEBUG = False
ALLOWED_HOSTS = ["$public_ip", "localhost"]

EOF