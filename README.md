# rocky9-pg17-bundle


This docker bundle includes most common packages available for Postgres 17.  This does not mean the package is configured and running. But available on the container for use.

Included packages are

 - postgresql17-contrib   
 - pgbackrest  
 - pgbouncer 
 - patroni-etcd  
 - pg_repack_17  
 - pg_top  
 - pg_activity  
 - repmgr_17  
 - haproxy 
 - proxysql pgpool-II-pg17  
 - etcd


## Quick start



### 1. Docker Image Building and Container Creation

To create the Docker image, clone the repository from the provided GitHub link and run the `docker build` command. This command builds an image tagged as **rocky9-pg17-bundle** from the `Dockerfile` in the local directory.

https://github.com/jtorral/rocky9-pg17-bundle

    docker build -t rocky9-pg17-bundle .


After building the image, a **custom network** named `pgnet` is created to allow communication between the containers.

    docker network create pgnet


The following demonstrates how to create three separate PostgreSQL containers (`pg1`, `pg2`, and `pg3`) and one Pgpool container (`pgpool`). 

Each `docker run` command uses specific flags:

-   `-p` Maps ports from the host to the container. For example, `-p 6431:5432` maps the host's port `6431` to the container's PostgreSQL port `5432`.
    
-   `--env=PGPASSWORD=postgres`  Sets the `PGPASSWORD` environment variable to `postgres` inside the container.
    
-   `-v`  Creates a **Docker volume** to persist the PostgreSQL data.
    
-   `--hostname` Assigns a hostname to the container.
    
-   `--network=pgnet`  Connects the container to the `pgnet` network.
    
-   `--name`  Assigns a name to the container for easy identification.
    
-   `-dt`  Runs the container in **detached mode** (`-d`) and allocates a pseudo-TTY (`-t`).


```
docker run -p 6431:5432 --env=PGPASSWORD=postgres -v pg1-pgdata:/pgdata --hostname pg1 --network=pgnet --name=pg1 -dt rocky9-pg17-bundle

docker run -p 6432:5432 --env=PGPASSWORD=postgres -v pg2-pgdata:/pgdata --hostname pg2 --network=pgnet --name=pg2 -dt rocky9-pg17-bundle

docker run -p 6433:5432 --env=PGPASSWORD=postgres -v pg3-pgdata:/pgdata --hostname pg3 --network=pgnet --name=pg3 -dt rocky9-pg17-bundle
```


***Note*** 

By default, the containers do not automatically start the PostgreSQL service. To start the service, you need to execute a command within the container or modify your docker run command to run it automatically. Just simply add the following to the docker run command.

```
--env=PGSTART=1
```

For example ...

```
docker run -p 6431:5432 --env=PGPASSWORD=postgres --env=PGSTART=1 -v pg1-pgdata:/pgdata --hostname pg1 --network=pgnet --name=pg1 -dt rocky9-pg17-bundle
```




#### Create a Pgpool container

```
docker run -p 7432:5432 -p 9999:9999 -p 9898:9898 --env=PGPASSWORD=postgres -v pgpool-pgdata:/pgdata --hostname pgpool  --network=pgnet --name=pgpool -dt rocky9-pg17-bundle
```
Just like the Postgres containers,  pgpool is on the pgnet docker network.

### 2. Starting PostgreSQL within a Container

By default, the containers do not automatically start the PostgreSQL service. To start the service, you need to execute a command within the container.

1.  Access the container's shell using `docker exec`

```
docker exec -it pg1 /bin/bash
```

This command provides an **interactive terminal** (`-i`) and allocates a pseudo-TTY (`-t`) to the `pg1` container.

2. Switch to the `postgres` user and start the PostgreSQL server

```
[root@pg1 /]# su - postgres  

[postgres@pg1 data]$ pg_ctl start  

waiting for server to start....2025-08-27 16:59:11.237 UTC [] [325]: [1-1] user=,db=,host= LOG: redirecting log output to logging collector process  
2025-08-27 16:59:11.237 UTC [] [325]: [2-1] user=,db=,host= HINT: Future log output will appear in directory "log".  
done  
server started  

[postgres@pg1 data]$ psql  
psql (17.6)  
Type "help" for help.
```

### 3. Accessing PostgreSQL

You can connect to the PostgreSQL instances from your local machine (outside the Docker container) using the `psql` command-line tool.

-   To connect, you need the **hostname** (`-h`), the **mapped port** (`-p`), the **username** (`-U`), and to be prompted for a password (`-W`).
    
-   For instance, to connect to the `pg1` container which is mapped to port `6431` 

```
psql -h localhost -p 6431 -U postgres -W
```

For example ...

```
jtorral@jt-p16-fedora:/GitStuff/rocky9-pg17-bundle$ psql -h localhost -p 6431 -U postgres -W  
Password:  
psql (17.5, server 17.6)  
Type "help" for help.  
  
postgres=#
```

