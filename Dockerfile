FROM rockylinux:9

RUN \
  dnf -y update \
  && dnf install -y wget \
  && dnf install -y https://dl.rockylinux.org/pub/rocky/9/CRB/x86_64/os/Packages/l/libmemcached-awesome-1.1.0-12.el9.x86_64.rpm \
  && dnf --enablerepo=crb install libmemcached-awesome \
  && dnf install -y telnet \
  && dnf install -y jq \
  && dnf install -y vim \
  && dnf install -y sudo \
  && dnf install -y gnupg \
  && dnf install -y openssh-server \
  && dnf install -y openssh-clients \
  && dnf install -y procps-ng \
  && dnf install -y net-tools \
  && dnf install -y iproute \
  && dnf install -y less \
  && dnf install -y watchdog \
  && dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm \
  && dnf -qy module disable postgresql \
  && dnf install -y postgresql17-server \
  && dnf install -y postgresql17-contrib \
  && dnf install -y epel-release \
  && dnf install -y libssh2 \
  && dnf install -y pgbackrest \
  && dnf install -y pgbouncer \
  && dnf install -y patroni-etcd \
  && dnf install -y pg_repack_17 \
  && dnf install -y pg_top \
  && dnf install -y pg_activity \
  && dnf install -y repmgr_17 \
  && dnf install -y haproxy \
  && dnf install -y https://www.pgpool.net/yum/rpms/4.6/redhat/rhel-9-x86_64/pgpool-II-release-4.6-1.noarch.rpm \
  && dnf install -y pgpool-II-pg17 \
  && dnf install -y pgpool-II-pg17-extensions

RUN mkdir -p /pgdata/17/

RUN chown -R postgres:postgres /pgdata
RUN chmod 0700 /pgdata

COPY pg_custom.conf /
COPY pg_hba.conf /
COPY pgsqlProfile /
COPY id_rsa /
COPY id_rsa.pub /
COPY authorized_keys /
COPY proxysql.cnf /

EXPOSE 22 80 443 5432 2379 2380 6032 6033 6132 6133 8432 5000 5001 8008 9999 9898 7000

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh 

SHELL ["/bin/bash", "-c"]
ENTRYPOINT /entrypoint.sh

