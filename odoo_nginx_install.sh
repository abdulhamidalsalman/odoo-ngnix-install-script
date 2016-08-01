#!/bin/bash
################################################################################
# Script for installing Odoo V9 on Ubuntu 14.04 LTS (could be used for other version too)
# Author: Yenthe Van Ginneken
# Modified By: Abdulhamid Alsalman
#-------------------------------------------------------------------------------
# This script will install Odoo and Nginx Reverse Proxy on your Ubuntu 14.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################

#--------------------------------------------------
# Fixed Parameters
#--------------------------------------------------
ODOO_USER="odoo"
ODOO_HOME="/$ODOO_USER"
ODOO_HOME_EXT="/$ODOO_USER/${ODOO_USER}-server"


#Choose the port on which your Odoo should run (xmlrpc-port)
ODOO_PORT="8069"

#Enter version for checkout "9.0" for version 9.0,"8.0" for version 8.0, "7.0 (version 7), "master" for trunk
ODOO_VERSION="9.0"

#set the superadmin password
ODOO_SUPERADMIN="admin"
ODOO_CONFIG="${ODOO_USER}-server"

#nginx reverse proxy parameters
DOMAIN_NAME="odoo.mycompany.com" #change with your domain
SRVR_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
ODOO_IP="$SRVR_IP"
ODOO_SRVR="$DOMAIN_NAME"
DOMAIN_NAME_PREFIX="https://"
NGINX_PORT="443"
NGINX_CONFIG="$DOMAIN_NAME" #file name for config

#SSL Configuration
SSL_EMAIL="admin@example.com" #email for let's encrypt info
SSL_CERT=/root/.acme.sh/$DOMAIN_NAME/fullchain.cer              #ssl_certificate
SSL_CERTK=/root/.acme.sh/$DOMAIN_NAME/${DOMAIN_NAME}.key        #ssl_certificate_key

#--------------------------------------------------
# WKHTMLTOPDF
# Ubuntu download links Trusty x64 & x32 === (for other distributions please replace these two links in order to have correct version of wkhtmltox installed, for a danger note refer to  https://www.odoo.com/documentation/8.0/setup/install.html#deb ):
#--------------------------------------------------
INSTALL_WKHTMLTOPDF="True"
WKHTMLTOX_X64=http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
WKHTMLTOX_X32=http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-i386.deb

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y locales

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Updating Locales ----"
sudo export LANGUAGE=en_US.UTF-8
sudo export LANG=en_US.UTF-8
sudo export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8
sudo dpkg-reconfigure locales

echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql -y

echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/9.3/main/postgresql.conf

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $ODOO_USER" 2> /dev/null || true

sudo service postgresql restart

#--------------------------------------------------
# System Settings
#--------------------------------------------------

echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$ODOO_HOME --gecos 'ODOO' --group $ODOO_USER

#The user should also be added to the sudo'ers group.
#sudo adduser $ODOO_USER sudo

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$ODOO_USER
sudo chown $ODOO_USER:$ODOO_USER /var/log/$ODOO_USER

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install wget unzip subversion git bzr bzrtools python-pip python-imaging python-setuptools python-dev libxslt-dev libxml2-dev libldap2-dev libsasl2-dev gdebi-core -y
	
echo -e "\n---- Install python packages ----"
sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil -y
	
echo -e "\n---- Install python libraries ----"
sudo pip install gdata psycogreen ofxparse

echo -e "\n--- Install other required packages"
sudo apt-get install node-clean-css -y
sudo apt-get install node-less -y
sudo apt-get install python-gevent -y
sudo apt-get install openssl bc curl

#--------------------------------------------------
# Let's encrypt install and configuration for SSL
#--------------------------------------------------
echo "*********************************"
echo "*                               *"
echo "*    Getting Let's encrypt      *"
echo "*                               *"
echo "*********************************"
echo -e "\n---- Install acme.sh for Let's encrypt  ----"
git clone https://github.com/Neilpang/acme.sh.git
cd acme.sh
./acme.sh --install  \
--accountemail  $SSL_EMAIL \
cd ~

cho -e "\n---- Install SSL Certificates for your domains  ----"
~/.acme.sh/acme.sh --issue -d $DOMAIN_NAME -d www.${DOMAIN_NAME} -d $ODOO_SRVR -w /usr/share/nginx/html

echo -e "\n---- Generate Strong Diffie-Hellman Group.  ----"
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048


#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 9 ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi
	


#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/odoo $ODOO_HOME_EXT/

echo -e "\n---- Create custom module directory ----"
sudo su $ODOO_USER -c "mkdir $ODOO_HOME/custom"
sudo su $ODOO_USER -c "mkdir $ODOO_HOME/custom/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME/*

#--------------------------------------------------
# Configure ODOO
#--------------------------------------------------
echo -e "* Create server config file"
sudo cp $ODOO_HOME_EXT/debian/openerp-server.conf /etc/${ODOO_CONFIG}.conf
sudo chown $ODOO_USER:$ODOO_USER /etc/${ODOO_CONFIG}.conf
sudo chmod 640 /etc/${ODOO_CONFIG}.conf

echo -e "* Change server config file"
echo -e "** Remove unwanted lines"
sudo sed -i "/db_user/d" /etc/$ODOO_CONFIG.conf
sudo sed -i "/admin_passwd/d" /etc/$ODOO_CONFIG.conf
sudo sed -i "/addons_path/d" /etc/$ODOO_CONFIG.conf
sudo sed -i "/xmlrpc_port/d" /etc/$ODOO_CONFIG.conf
sudo sed -i "/proxy_mode/d" /etc/$ODOO_CONFIG.conf

echo -e "** Add correct lines"
sudo su root -c "echo 'db_user = $ODOO_USER' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'admin_passwd = $ODOO_SUPERADMIN' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'logfile = /var/log/$ODOO_USER/$ODOO_CONFIG$1.log' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'addons_path=$ODOO_HOME_EXT/addons,$ODOO_HOME/custom/addons' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'xmlrpc_port = $ODOO_PORT' >> /etc/$ODOO_CONFIG.conf"
sudo su root -c "echo 'proxy_mode = True' >> /etc/$ODOO_CONFIG.conf"


echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $ODOO_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $ODOO_USER $ODOO_HOME_EXT/openerp-server --config=/etc/${OE_CONFIG}.conf' >> $ODOO_HOME_EXT/start.sh"
sudo chmod 755 $ODOO_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$ODOO_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $ODOO_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$ODOO_HOME_EXT/openerp-server
NAME=$ODOO_CONFIG
DESC=$ODOO_CONFIG
# Specify the user name (Default: odoo).
USER=$ODOO_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$ODOO_CONFIG /etc/init.d/$ODOO_CONFIG
sudo chmod 755 /etc/init.d/$ODOO_CONFIG
sudo chown root: /etc/init.d/$ODOO_CONFIG

echo -e "* Start ODOO on Startup"
sudo update-rc.d $ODOO_CONFIG defaults

echo -e "* Starting Odoo Service"
sudo su root -c "/etc/init.d/$ODOO_CONFIG start"

#--------------------------------------------------
# Installing NGINX reverse proxy
#--------------------------------------------------
sudo apt-get install nginx -f -y

NGINX_CONFIG_AVAILABLE="/etc/nginx/sites-available/$NGINX_CONFIG" #the config file
NGINX_CONFIG_ENABLED="/etc/nginx/sites-enabled/$NGINX_CONFIG" #the link path
echo -e "\n- NGINX config file location = $NGINX_CONFIG_AVAILABLE"

echo -e "* Create init file"
cat <<EOF > ~/$NGINX_CONFIG
#odoo server
upstream odoo {
    server 127.0.0.1:8069;
}

upstream odoochat {
    server 127.0.0.1:8072;
}

## http redirects to https ##
server {
    listen 80;
    server_name $DOMAIN_NAME;

    # Strict Transport Security
    add_header Strict-Transport-Security max-age=2592000;
    rewrite ^/.*$ https://$host$request_uri? permanent;
}

server {
    # server port and name
    listen 443;
    server_name $DOMAIN_NAME;
    #general proxy settings
    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    # force timeouts if the backend dies
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
	
    # set headers
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;


    # Specifies the maximum accepted body size of a client request,
    # as indicated by the request header Content-Length.
    client_max_body_size 200m;

    # add ssl specific settings
    keepalive_timeout 60;
    ssl on;
    ssl_certificate /etc/ssl/nginx/server.crt;
    ssl_certificate_key /etc/ssl/nginx/server.key;
    ssl_session_timeout 30m;
    # limit ciphers
    ssl_ciphers HIGH:!ADH:!MD5;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;

    # increase proxy buffer to handle some OpenERP web requests
    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    # log
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;


    # by default, do not forward anything
    proxy_buffering off;

    location / {
        proxy_redirect off;
        proxy_pass http://odoo;
    }

    location /longpolling {
        proxy_pass http://odoochat;
    }

    # cache some static data in memory for 60mins.
    # under heavy load this should relieve stress on the OpenERP web interface a bit.
    location /web/static/ {
        proxy_cache_valid 200 60m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo8;
    }
     # common gzip
    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
    gzip on;
}
EOF

echo -e "* Security Init NGINX Config File"
sudo mv ~/$NGINX_CONFIG $NGINX_CONFIG_AVAILABLE
sudo chown root:root $NGINX_CONFIG_AVAILABLE
sudo chmod 640 $NGINX_CONFIG_AVAILABLE


echo -e "\n---- Disabled the default site by deleting the symbolic link for it.  ----"
rm /etc/nginx/sites-available/default

#activate site
ln -s /$NGINX_CONFIG_AVAILABLE $NGINX_CONFIG_ENABLED
#restart service
sudo service nginx reload

echo "******************************************************************"
echo "	Installation of ODOO $ODOO_GIT_VERSION complete"
echo ""
echo "	Start/Stop server with /etc/init.d/$ODOO_CONFIGFILE_NAME"
echo ""
echo "	The server is available internaly:"
echo "	http://localhost:8069 "
echo "	The server is available externaly:"
echo "	$DOMAIN_NAME_PREFIX$DOMAIN_NAME:$NGINX_PORT"
echo "******************************************************************"


echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $ODOO_PORT"
echo "User service: $ODOO_USER"
echo "User PostgreSQL: $ODOO_USER"
echo "Code location: $ODOO_USER"
echo "Addons folder: $ODOO_USER/$ODOO_CONFIG/addons/"
echo "Start Odoo service: sudo service $ODOO_CONFIG start"
echo "Stop Odoo service: sudo service $ODOO_CONFIG stop"
echo "Restart Odoo service: sudo service $ODOO_CONFIG restart"
echo "-----------------------------------------------------------"
