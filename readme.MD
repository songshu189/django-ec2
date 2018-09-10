## Django with Postgres, pipenv, gunicorn, nginx on AWS EC2 Ubuntu 18.04
### Create an EC2 AWS instance
Step 1 **Choose an AMI**

    Search for Ubuntu Server 18.04 from AWS Marketplace (Bionic Beaver)

Step 2 **Choose an Instance Type**, default **t2.micro**

Step 3 **Configure Instance Details**,  **Auto-assign Public IP**: **Enable**

Step 4 **Add Storage**

Step 5 **Add Tags**

Step 6 **Configure Security Group**

   Add Rule

   HTTP (80), HTTPS (443)

Step 7 **Review Instance Launch**

   Choose **Launch**

   In the **Select an existing key pair or create a new key pair** dialog box, choose **create a new key pair**, and in the **Key pair name** input box, input your key pair name: `django-key`, click **Download Key Pair** to download key pair file to your computer. A file named `django-key.perm` is saved to your computer.

   Click **Launch Instance** button, your EC2 instance will be created.

   In the next page, click **View Instance**

## PuTTY Download
Goto https://www.putty.org/ page. There is a You can download PuTTY [here](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html). Click `here` redirects to putty download page.

* download **putty.exe 64-bit** and **puttygen.exe 64-bit** to your computer.
* run puttygen.exe, click **Load**, load the file `django-key.perm` you downloaded when launch EC2 instance.
* click **Save private key**, a PuTTYgen Warning dialogbox pops up, click **Yes**, a file named `django-key.ppk` is saved to your computer, remember the file path.
* close puttygen
* run putty.exe
* Now your EC2 **instance state** is `running`,  copy **Public DNS (IPv4)**(something like `ec2-35-27-189-68.us-west-1.compute.amazonaws.com`) to the **HostName(or IP address)** input box of Session Category of PuTTy Configuration.
* Input auto-login username

  Connection -> Data -> Auto-login username: `ubuntu`
* Load generated private key

  Connection -> SSH  -> Auth -> **Browse...** load `django-key.ppk`
* Save session for later reuse

  Session -> Saved Session, input `Django AWS` -> **save**, the configuration is saved, next time you can use **load** to load `Django AWS` configuration.
* Connect to AWS EC2 VPS

  Click **Open**, A PuTTY Security Alert pops up, click **yes**.

  Now you are connected to Amazon VPS

## VPS setup

1. Update the repository
```
    $ sudo apt update
```
2. Install pip for python3
```
    $ sudo apt install python3-pip python3-dev
```
3. Install pipenv
```
    $ pip3 install --user pipenv
```
4. Add pipenv (and other python scripts) to PATH
```
    $ echo "PATH=$HOME/.local/bin:$PATH" >> ~/.bashrc
    $ source ~/.bashrc
```
5. Install nginx, git and unzip
```
    $ sudo apt install nginx
    $ sudo apt install git
    $ sudo apt install unzip
```
6. Install PostgreSQL
```
    $ sudo apt install libpq-dev postgresql postgresql-contrib
```
7. Create database and user
```sql
    $ sudo -u postgres psql
    postgres=# create databse $dbname;
    postgres=# create user $dbuser with password '$dbpassword'
    postgres=# alter role $dbuser set client_encoding to 'utf8';
    postgres=# alter role $dbuser set default_transaction_isolation to 'read commited'
    postgres=# alter role $dbuser set timezone to 'UTC';
    postgres=# grant all privileges on databse $dbname to $dbuser;
    postgres=# \q
```
Replace $dbname, $dbuser, $dbpassword with database name, user and password you set.

8. Make a working folder
```
    mkdir ~/sites
    cd ~/sites
```

## Install a Django project
If there is a project which has been pushed to github.
1. Clone the github project
```
    $ git clone https://github.com/username/myproject.git
```
2. Install related pacakges
```
    $ cd myproject
    $ pipenv install
```
Relevanted packages in `Pipfile` are installed and a new virtual environmented is created.

3. If gunicorn is not included in `Pipfile`, install `gunicorn`
```
    $ pipenv install gunicorn
```
4. Adjust the Project settings

Edit the settings.py of the project, make the following adjustments including ALLOWED_HOST, database setting, ensure DEBUG=False.
```
DEBUD = False
ALLOWED_HOSTS = ['your_EC2_instance_Public_IP', 'localhost']
SECRET_KEY = 'production_secret_key'
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql_psycopg2",
        "NAME": "$dbname",
        "USER": "$dbuser",
        "PASSWORD": "$password",
        "HOST": "localhost",
        "PORT": "5432",
    }
}
```
Copy your_EC2_instance_Public_IP from your EC2 instance public IP (something like 35.27.189.68).

5. Migrate the initial database schema
```
    $ python manage.py makemigrations
    $ python manage.py migrate
```
6. Create an administrative user for the project
```
    $ python manage.py createsuperuser
```
7. Collect all of the static content into the directory location
```
    $ python manage.py collectstatic
```
Be sure these two lines in your settings.py before you `collectstatic`.
```
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static/')
```
8. Allow port 8000 access
```
    $ sudo ufw allow 8000
```
9. Let the project running
```
    $ python manage.py runserver 0.0.0.0:8000
```

Access website from your browser with `http://35.27.189.68:8000`, if it shows
```
    This site can't be reached
```
Then open port 8000 from security groups. In AWS EC2 view instance window, scroll down to Description section, Security groups, click `launch-wizard-1`, in the next screen, low part `Inbound` tab pane, click **Edit**, **Edit inbound rules** dialog box pops up, click **Add Rule** add a rule which allows 8000 inbound access. Refresh the above page, it should work, (static files not serve yet).

10. Testing gunicorn's ability to serve the project

Run the following command, where myproject should be the folder name where wsgi.py resides, settings.py also in that folder.
```
    $ gunicorn --bind 0.0.0.0:8000 myproject.wsgi
```
Your webpage should also work (not serve static) by accessing `http://35.27.189.68:8000`,

Now back out of the virtual environment, by
```
    $ exit
```
The virtual environment indicator in your prompt will be removed. you've exited from pipenv virtual environment.

### Create systemd gunicorn.service

Create a systemd service file for Gunicorn
```
    $ sudo vim /etc/systemd/system/gunicorn.service
```
The content of gunicorn.service is as follows
```
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
```

$working_folder is the full path of project folder which we can get by `pwd`, $gunicorn_path is the gunicorn executive path which we get by `which gunicorn`, $folder_name is the project folder name, $wsgi_folder is the folder name which wsgi.py resides in.

Start the Gunicorn service we created and enable it
```
    $ sudo systemctl start gunicorn
    $ sudo systemctl enable gunicorn
```
Check the status of the process to see whether it started or not
```
    $ sudo systemctl status gunicorn
```
With the following command
```
    $ ls /home/ubuntu/myproject
```
You will find there is a sock file `myproject.sock` created

If there is an error occurred or if you do not find the myproject.sock file, check the Gunicorn process logs by
```
    $ sudo journalctl -u gunicorn
```
If you made changes to gunicorn.service, with the following, you can restart gunicorn serivce
```
    $ sudo systemctl daemon-reload
    $ sudo systemctl restart gunicorn
```
Now copy public dns(something like `ec2-35-27-189-68.us-west-1.compute.amazonaws.com`) to your browser and refresh, you will find the following shows

**`Welome to nginx!`**

### Configure Nginx to pass traffic to gunicorn process
Creat a new server block in Nginx's `sites-available` folder
```
    $ sudo vim /etc/nginx/sites-available/myproject
```
`myproject` is your real project name. the content of it is as follows
```
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
```
Replace with $public_ip, $working_folder, $folder_name with yours

Enable the file by linking it to the `sites-enabled` folder
```
    $ sudo ln -s /etc/nginx/site-available/myproject /etc/nginx/sites-enabled
```
If there is any syntax errors, the follow command will show you of any problems in your configuration files.
```
    $ sudo nginx -t
```
If no errors, restart Nginx
```
    $ sudo systemctl restart nginx
```
Manage firewall, remove the rule to allow port 8000(we no longer need the development sever), allow 'Nginx Full' to open both HTTP(80) and HTTPS(443) ports.
```
    $ sudo ufw delete allow 8000
    $ sudo ufw allow 'Nginx Full'
```
Refresh http://35.27.189.68, your website works and it serves static contents.
