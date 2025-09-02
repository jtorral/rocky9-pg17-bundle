#!/bin/bash

if [ ! -f "/pgdata/17/data/PG_VERSION" ]
then
        sudo -u postgres /usr/pgsql-17/bin/initdb -D /pgdata/17/data
        echo "include = 'pg_custom.conf'" >> /pgdata/17/data/postgresql.conf
        cp /pg_custom.conf /pgdata/17/data/
        cp /pg_hba.conf /pgdata/17/data/
        cp /pgsqlProfile /var/lib/pgsql/.pgsql_profile


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
        sudo -u postgres psql -c "ALTER ROLE postgres PASSWORD 'postgres';"

        if [ -z "$PGSTART" ]
        then
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data stop
        else
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data restart
        fi
else
        if [ -z "$PGSTART" ]
        then
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data start
        fi
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


# Copy and setup compiled version of haproxy since only old version is available for this os
#cp /haproxy /usr/sbin/
#chmod 0755 /usr/sbin/haproxy
#mkdir /etc/haproxy



# Install latest proxysql

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


# Setup some ssh stuff

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

#exec tail -f /dev/null
#sleep infinity
