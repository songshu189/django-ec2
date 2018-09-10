#!/bin/bash
gunicorn_path=$(which gunicorn)
working_folder=$(pwd)
folder_name=${PWD##*/}
echo $gunicorn_path
if [ -z "$gunicorn_path" ]; then
    echo "Please install gunicorn first!"
    exit
fi
echo $working_folder
echo $folder_name
wsgi_file=$(find . -maxdepth 2 -name "wsgi.py")
wsgi_path=$(dirname $wsgi_file)
wsgi_folder=${wsgi_path##*/}
sudo cat <<EOF > /etc/systemd/system/gunicorn.service
[Unit]
Description=gunicorn daemon
After=nextwork.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=$working_folder
ExecStart=$gunicorn_path --access-logfile - --workers 3 --bind unix:$working_folder/$folder_name.sock ${wsgi_folder}.wsgi:application

[Install]
WantedBy=multi-user.target
EOF