#!/bin/bash
if [ -z "$1" ] && [ -z "$dbname" ]; then
    echo "Please input databse name:"
    read dbname
elif [ -z "$dbname" ]; then
    dbname=$1
fi
if [ -z "$2" ] && [ -z "$dbuser" ]; then
    echo "Please input user name:"
    read dbuser
elif [ -z "$dbuser" ]; then
    dbuser=$2
fi
if [ -z "$3" ] && [ -z "$password" ]; then
    echo "Please input password:"
    read password
elif [ -z "$password" ]; then
    password=$3
fi
sudo -u postgres psql << EOF
create databse $dbname;
create user $dbuser with password '$password'
alter role $dbuser set client_encoding to 'utf8';
alter role $dbuser set default_transaction_isolation to 'read commited'
alter role $dbuser set timezone to 'UTC';
grant all privileges on databse $dbname to $dbuser;
\q

EOF

sudo cat <<EOF >> local_settings.py
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

EOF