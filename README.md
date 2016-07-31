# odoo-9-installation-script

This script combines the best parts of aschenkels-ictstudio & Yethe666 odoo 9 installation scripts. I used Yethe666 as template and added few commands from aschenkel-sictstudio.

The added commands do:<br />
1. make UTF-8 the default language for postgres <br />
2. make postgres server listens to requests from any TCP/IP address.<br />
3. restart postgres server to apply the modifications above<br />

This script can be safely used in a multi-odoo code base server because the default Odoo port is changed BEFORE the Odoo is started.

<h3>Installation procedure</h3>
1. Download the script:
```
sudo wget https://github.com/abdulhamidalsalman/odoo-9-installation-script/odoo_install.sh 
```
2. Make the script executable:
```
sudo chmod +x odoo_install.sh
```
3. Execute the script:
```
sudo ./odoo_install.sh
```


<strong>Below are the lines of code copied from aschenkels-ictstudio script:<strong/>
```
sudo apt-get install -y locales
sudo export LANGUAGE=en_US.UTF-8
sudo export LANG=en_US.UTF-8
sudo export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8
sudo dpkg-reconfigure locales

echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/9.4/main/postgresql.conf

sudo service postgresql restart
```
