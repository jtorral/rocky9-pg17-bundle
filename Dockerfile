FROM rockylinux:9.3

# --- System Updates, Base Utilities, and CRB Setup ---

RUN dnf -y update \
    && dnf install -y wget telnet jq vim sudo gnupg openssh-server openssh-clients \
        procps-ng net-tools iproute iputils less diffutils watchdog \
    # Install libmemcached and enable CRB in the same step
    && dnf install -y https://dl.rockylinux.org/pub/rocky/9/CRB/x86_64/os/Packages/l/libmemcached-awesome-1.1.0-12.el9.x86_64.rpm \
    && dnf --enablerepo=crb install -y libmemcached-awesome \
    # Clean up DNF cache
    && dnf clean all && rm -rf /var/cache/dnf

# --- Install EPEL Repository ---
# EPEL must be installed in its own layer to ensure the repo is ready for the next step

RUN dnf install -y epel-release \
    && dnf clean all && rm -rf /var/cache/dnf

# --- Install Postgres PGDG Repo and Core Packages ---
# Using --nobest to handle potential OpenSSL dependency conflicts

RUN dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm \
    && dnf -qy module disable postgresql \
    && dnf install -y --nobest postgresql17-server postgresql17-contrib \
    && dnf clean all && rm -rf /var/cache/dnf

# --- Install Remaining Postgres HA/Extension Tools using EPEL packages ---

RUN dnf install -y libssh2 pgbackrest pgbouncer patroni-etcd \
    pg_repack_17 pg_top pg_activity repmgr_17 haproxy \
    && dnf clean all && rm -rf /var/cache/dnf

# --- Install PGPool ---

RUN dnf install -y https://www.pgpool.net/yum/rpms/4.6/redhat/rhel-9-x86_64/pgpool-II-release-4.6-1.noarch.rpm \
    && dnf install -y pgpool-II-pg17 pgpool-II-pg17-extensions \
    && dnf clean all && rm -rf /var/cache/dnf


# --- Create data and config directories ---

RUN mkdir -p /pgdata/17/
RUN chown -R postgres:postgres /pgdata
RUN chmod 0700 /pgdata

RUN chown -R postgres:postgres /etc/pgpool-II
RUN chown -R postgres:postgres /etc/pgbackrest.conf

RUN mkdir -p /var/log/etcd
RUN mkdir -p /var/log/patroni
RUN chown -R postgres:postgres /var/log/etcd
RUN chown -R postgres:postgres /var/log/patroni

RUN mkdir -p /pgha/{config,certs,data/{etcd,postgres,pgbackrest}}
RUN chown -R postgres:postgres /pgha

# --- COPY Files  ---

COPY pg_custom.conf /
COPY pg_hba.conf /
COPY pg_hba_md5.conf /
COPY pgsqlProfile /
COPY id_rsa /
COPY id_rsa.pub /
COPY authorized_keys /
COPY proxysql.cnf /
COPY recovery_1st_stage /
COPY follow_primary.sh /
COPY pgpool_remote_start /
COPY failover.sh /
COPY etcdSetup.sh /
COPY patroniSetup.sh /
COPY createRoles.sh /
COPY stopPatroni /
COPY startPatroni /

# --- Set Ownerships ---

RUN chown postgres:postgres /recovery_1st_stage
RUN chown postgres:postgres /follow_primary.sh
RUN chown postgres:postgres /pgpool_remote_start
RUN chown postgres:postgres /failover.sh
RUN chown postgres:postgres /etcdSetup.sh
RUN chown postgres:postgres /patroniSetup.sh
RUN chown postgres:postgres /createRoles.sh
RUN chown postgres:postgres /stopPatroni
RUN chown postgres:postgres /startPatroni

# --- Set Permissions ---

RUN chmod 755 /recovery_1st_stage
RUN chmod 755 /follow_primary.sh
RUN chmod 755 /pgpool_remote_start
RUN chmod 755 /failover.sh
RUN chmod 755 /etcdSetup.sh
RUN chmod 755 /patroniSetup.sh
RUN chmod 755 /createRoles.sh
RUN chmod 755 /startPatroni
RUN chmod 755 /stopPatroni

# --- Expose Ports ---

EXPOSE 22 80 443 5432 2379 2380 6032 6033 6132 6133 8432 5000 5001 8008 9999 9898 7000

# --- Entrypoint ---

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
SHELL ["/bin/bash", "-c"]
ENTRYPOINT /entrypoint.sh
