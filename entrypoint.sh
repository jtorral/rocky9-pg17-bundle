#!/bin/bash

if [ ! -f "/pgdata/17/data/PG_VERSION" ]
then
        sudo -u postgres /usr/pgsql-17/bin/initdb -D /pgdata/17/data
        echo "include = 'pg_custom.conf'" >> /pgdata/17/data/postgresql.conf
        cp /pg_custom.conf /pgdata/17/data/
        cp /pg_hba.conf /pgdata/17/data/
        cp /pgsqlProfile /var/lib/pgsql/.pgsql_profile

        if [ -n "$MD5" ]
        then
           echo 
           echo "=========================================================="
           echo "env MD5 is set. Setting postgres to use md5 authentication"
           echo "=========================================================="
           echo 
           cp /pg_hba_md5.conf /pgdata/17/data/pg_hba.conf
           echo "password_encryption = md5 " >> /pgdata/17/data/pg_custom.conf
        fi

	# add ssh keys
	mkdir -p /var/lib/pgsql/.ssh
        cp /id_rsa /var/lib/pgsql/.ssh
        cp /id_rsa.pub /var/lib/pgsql/.ssh
        cp /authorized_keys /var/lib/pgsql/.ssh
        chown -R postgres:postgres /var/lib/pgsql/.ssh
        chmod 0700 /var/lib/pgsql/.ssh
        chmod 0600 /var/lib/pgsql/.ssh/*

        chown postgres:postgres /var/lib/pgsql/.pgsql_profile
        chown postgres:postgres /pgdata/17/data/pg_custom.conf
        chown postgres:postgres /pgdata/17/data/pg_hba.conf
        sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data start

        if [ ! -z "$PGPASSWORD" ]
        then
           echo 
           echo "=========================================================="
           echo "env PGPASSWORD is set. Setting postgres password"
           echo "=========================================================="
           echo 
           sudo -u postgres psql -c "ALTER ROLE postgres PASSWORD '$PGPASSWORD';"
        else
           echo 
           echo "=========================================================================="
           echo "env PGPASSWORD is not set. Setting default postgres password of \"postgres\""
           echo "=========================================================================="
           echo 
           sudo -u postgres psql -c "ALTER ROLE postgres PASSWORD 'postgres';"
        fi

        sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data stop

        if [ -n "$PGSTART" ]
        then
           echo
           echo "=========================================================================="
           echo "env PGSTART is set. Enabling auto starting of postgres on container starts"
           echo "=========================================================================="
           echo
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data restart
        else
           echo
           echo "=========================================================="
           echo "env PGSTART is not set. Skipping auto starting of postgres"
           echo "=========================================================="
           echo
           echo "PGSTART not set. Skipping starting of postgres"
        fi

else

        if [ -n "$PGSTART" ]
        then
           echo
           echo "=========================================================================="
           echo "env PGSTART is set. Enabling auto starting of postgres on container starts"
           echo "=========================================================================="
           echo
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data restart
        else
           echo
           echo "=========================================================="
           echo "env PGSTART is not set. Skipping auto starting of postgres"
           echo "=========================================================="
           echo
           echo "PGSTART not set. Skipping starting of postgres"
        fi


fi



# -- Lets create preconfigure or not based on preset env variable
# -- This is for pgpool. If used for training it gives option of going throuh
# -- the process instead of just preconfigured files to be used

if [ -z "$DONTPRECONFIG" ]
then

   echo
   echo "==============================================================="
   echo "env DONTPRECONFIG is not set. Applying preconfig to some files "
   echo "==============================================================="
   echo

   # -- Setup sudoers
   echo "postgres ALL=NOPASSWD: /usr/sbin/ip  " >> /etc/sudoers
   echo "postgres ALL=NOPASSWD: /usr/sbin/arping " >> /etc/sudoers

   # -- Copy some preconfigures scripts
   cp -p /recovery_1st_stage /etc/pgpool-II/
   cp -p /follow_primary.sh /etc/pgpool-II/
   cp -p /pgpool_remote_start /etc/pgpool-II/
   cp -p /failover.sh /etc/pgpool-II/

else

   echo
   echo "================================================================================="
   echo "env DONTPRECONFIG is set. Not applying preconfigs so you have to manually do them"
   echo 
   echo "This includes not making changes to :"
   echo "/etc/sudoers"
   echo "Modifying the recovery scripts for Pgpool"
   echo "================================================================================="
   echo

fi





# Install etcd from google

ETCD_VER=v3.5.17
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
/tmp/etcd-download-test/etcd --version
/tmp/etcd-download-test/etcdctl version
/tmp/etcd-download-test/etcdutl version
cp -p /tmp/etcd-download-test/etcd /usr/bin/
cp -p /tmp/etcd-download-test/etcdctl /usr/bin/
cp -p /tmp/etcd-download-test/etcdutl /usr/bin/
cd /tmp
rm -rf /tmp/etcd-download-test


# Install latest proxysql 3.x

cat > /etc/yum.repos.d/proxysql.repo << EOF
[proxysql]
name=ProxySQL YUM repository
baseurl=https://repo.proxysql.com/ProxySQL/proxysql-3.0.x/centos/\$releasever
gpgcheck=1
gpgkey=https://repo.proxysql.com/ProxySQL/proxysql-3.0.x/repo_pub_key
EOF

dnf install -y proxysql

mkdir -p /pgdata/proxysql
cp /proxysql.cnf /etc/
chown -R proxysql:proxysql /pgdata/proxysql


# Preconfigure some pgbackrest stuff

echo 
echo "====================================================================="
echo "Setting up pgbackrest directory structue and file privs to use /pgha/"
echo "centralized location and data"
echo "====================================================================="

if [ ! -f "/pgha/config/pgbackrest.conf" ]
then 
   touch /pgha/config/pgbackrest.conf
   chown postgres:postgres /pgha/config/pgbackrest.conf
   mv /etc/pgbackrest.conf /etc/pgbackrest.conf.save
   ln -s /pgha/config/pgbackrest.conf /etc/pgbackrest.conf
fi


# Setup ssh for root using same keys as postgres

echo
echo "========================================================================"
echo "This is NOT secure. But this is for our own Docker environment so I "
echo "guess it's ok. We are setting up ssh for roo as well usingthe same keys"
echo "we use for user postgres. Just being lazy. Change afterwards if you want"
echo "========================================================================"
echo 

if [ ! -f "/root/.ssh/id_rsa" ]
then
   mkdir -p /root/.ssh
   cp /id_rsa /root/.ssh
   cp /id_rsa.pub /root/.ssh
   cp /authorized_keys /root/.ssh
   chown -R root:root /root/.ssh
   chmod 0700 /root/.ssh
   chmod 0600 /root/.ssh/*
fi



# Setup some preconfigured ssh for trusting user postgres between containers

echo
echo "======================================================================"
echo "Doing some ssh voodoo so you don't have to. Even if you dont preconfig"
echo "======================================================================"
echo 

if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]
then
   ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
   ssh-keygen -t dsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
   ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
fi


echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

/usr/sbin/sshd



rm -f /run/nologin

# /bin/bash better option than the tail -f especially without a supervisor
# consider using dumb_init in the future as a supervisor https://github.com/Yelp/dumb-init
 
/bin/bash
