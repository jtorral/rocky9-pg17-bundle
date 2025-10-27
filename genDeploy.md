
# genDeploy

### Jorge Torralba

  
### This is a new file so not use this yet for reference 

This is a home brewed option to docker-compose for use with the docker image you create from this repo.  It is a first go at the project and can use feedback and improvement.  I will eventually be customized to be more flexible and universal.

## What it does

It creates a way for yoy to manage your docker deploy of this Pgpool repo and it's assets in a way similar to docker-compose by generating a shell script you can use to manage the deploy.

    Usage:
            ./build-docker-env [OPTION]
    
            -c Name for containers. ( Defaults = pg)
            -n number of of containers. (default = 1)
            -s Subnet. First 3 octets only. Example  172.28.100 
            -w Name for docker network to create (default = pgnet)
            -y Create the netork. Otherwise, just use the existing network
            -m Setup postgres environment to use md5 password_encription
            -p Password for user postgres. If usinmg special characters like #! etc .. escape them with a \ ( default = "postgres" )
            -i docker image to use. Must be one of the images listed in the repo's README. ( default = rocky9_pg17_pgpool )


### For example

If you wish to create a deploy of a single Postgres node with the name  **pgdemo** running on a custom docker network called  **pgdemonet** with a subnet of **192.168.10**  you would run the following .

    ./build-docker-env -s 192.168.10 -w pgdemonet -c pgdemo

Which would output the following:


    The following file: DockerRunThis.pgdemo,  contains the needed docker run commands
    
    
            ALERT -- Before starting the containers you must manually create the network pgdemonet as shown below. Or run the command again with the -y option
    
            docker network create --driver bridge --subnet 192.168.10.0/24 --gateway 192.168.10.1 pgdemonet 


If you were to add the **-y** option

    ./build-docker-env -s 192.168.10 -w pgdemonet -c pgdemo -y

This would be the output

    The following file: DockerRunThis.pgdemo,  contains the needed docker run commands

In either case with or without the **-y** a successful run will generate the **DockerRunThis** file with the extension of the container name. **DockerRunThis.pgdemo**

Lets say you want 3 Postgres nodes. Use the **-n** option.

    ./build-docker-env -s 192.168.10 -w pgdemonet -c pgdemo -y -n 3

Again, you get the following message

    The following file: DockerRunThis.pgdemo,  contains the needed docker run commands

In our example above **DockerRunThis.pgdemo** is our version of a docker-compose file. And from here you can control what to do.

    Usage:
    ./DockerRunThis.pgdemo [OPTION]
            -a OPTIONS [start stop run rm rmvolumes delete createnetwork] 
            -f force the delete of volumes. Otherwise, they are preserved



### Running the containers

     ./DockerRunThis.pgdemo -a run
     
    8a80a92ec19f28a19c86b660bd052b217434a3a115122479a5a8e8e67edc64b7
    384e0a2632f03bca3ed883b453d21b03e598ddab1d442a4fbb2a3a4be02f0ba4
    000ab649ef2be84f34a3f09a586c864ff363bf6be5547d91ae0465c388e9da19
    d26534faf200c861bcb4af03d09daa3308ee49108fe6328a14652962c6901223


The above created the Network and the containers

    CONTAINER ID   IMAGE                COMMAND                  CREATED              STATUS              PORTS                                                                                                                         NAMES
    d26534faf200   rocky9_pg17_pgpool   "/bin/bash -c /entry…"   About a minute ago   Up About a minute   22/tcp, 80/tcp, 443/tcp, 9898/tcp, 0.0.0.0:6436->5432/tcp, [::]:6436->5432/tcp, 0.0.0.0:9996->9999/tcp, [::]:9996->9999/tcp   pgdemo3
    000ab649ef2b   rocky9_pg17_pgpool   "/bin/bash -c /entry…"   About a minute ago   Up About a minute   22/tcp, 80/tcp, 443/tcp, 9898/tcp, 0.0.0.0:6435->5432/tcp, [::]:6435->5432/tcp, 0.0.0.0:9995->9999/tcp, [::]:9995->9999/tcp   pgdemo2
    384e0a2632f0   rocky9_pg17_pgpool   "/bin/bash -c /entry…"   About a minute ago   Up About a minute   22/tcp, 80/tcp, 443/tcp, 9898/tcp, 0.0.0.0:6434->5432/tcp, [::]:6434->5432/tcp, 0.0.0.0:9994->9999/tcp, [::]:9994->9999/tcp   pgdemo1

And the **pgdemonet** network

    docker network ls
    NETWORK ID     NAME        DRIVER    SCOPE
    7ca26fc20206   bridge      bridge    local
    d79e759c7a31   host        host      local
    8a80a92ec19f   pgdemonet   bridge    local
    5b44e038202c   poolnet     bridge    local

Our data is persistent with volumes. So you can delete the containers and retain the data. Doing so allows you to recreate the containers and access the data previoulsy stored.

    docker volume ls
    DRIVER    VOLUME NAME
    local     pg1-pgdata
    local     pg2-pgdata
    local     pg3-pgdata
    local     pgdemo1-pgdata
    local     pgdemo2-pgdata
    local     pgdemo3-pgdata
    local     pool1-pgdata
    local     pool2-pgdata

You can see the volumes above for pgdemo1, 2 and 3 

### Stopping the containers

    ./DockerRunThis.pgdemo -a stop

You can see they are stopped now

    ./DockerRunThis.pgdemo -a stop
    pgdemo1
    pgdemo2
    pgdemo3

### Starting the containers

    ./DockerRunThis.pgdemo -a start
    pgdemo1
    pgdemo2
    pgdemo3

### Deleting the entire deploy

Similar to docker-compose down 

    ./DockerRunThis.pgdemo -a delete -f 

We used the -f option to force delete the volumes

    ./DockerRunThis.pgdemo -a delete -f 
    pgdemo1
    pgdemo2
    pgdemo3
    pgdemo1
    pgdemo2
    pgdemo3
    pgdemonet
    pgdemo1-pgdata
    pgdemo2-pgdata
    pgdemo3-pgdata

Without the **-f**, we would still retain the volumes but can still delete them.  

For example, lets recreate everything again.

    ./DockerRunThis.pgdemo -a run
    d7967c913f9783881a21628b9e3cccf4c90128d0aab22a680c7e08f488164e5a
    56bdc54687294ddbfcadc5918e8439864208e039dc1ce04723e0fab9cba7477e
    e13ea756623a09dc49759139804c74ceb38cbd90d74016214a2a31fe39f8a324
    fb193de88c53afd6195159070302f670d0fab8080f69768ec5ff8f35c257179b

Now lets delete the environment **without the -f** option

    ./DockerRunThis.pgdemo -a delete 
    pgdemo1
    pgdemo2
    pgdemo3
    pgdemo1
    pgdemo2
    pgdemo3
    pgdemonet

Notice the volumes were not deleted

    docker volume ls
    DRIVER    VOLUME NAME
    local     pg1-pgdata
    local     pg2-pgdata
    local     pg3-pgdata
    local     pgdemo1-pgdata
    local     pgdemo2-pgdata
    local     pgdemo3-pgdata
    local     pool1-pgdata
    local     pool2-pgdata

### Deleting the volumes

To actually delete the volumes after destroying the environment, simply run the following.

    ./DockerRunThis.pgdemo -a rmvolumes

Which removes the volumes only

    ./DockerRunThis.pgdemo -a rmvolumes
    pgdemo1-pgdata
    pgdemo2-pgdata
    pgdemo3-pgdata



## What if ....

### You want to build the environment and use an existing Network


If you wish to create a deploy of a single Postgres node with the name  **pgdemo** running on a custom docker network called  **poolnet** with a subnet of **192.168.10**  you would run the following .

In the above example, the network poolnet already exists. But it has a subnet different than 192.168.10


**./build-docker-env -s 192.168.10 -w poolnet -c pgdemo -y -n 3**

You will get the following message

    ERROR -- The network "poolnet" already exist. run without -y option to use this network


Lets run the command without the **-y** to force it to use the existing **poolnet** network

This is the output

    ./build-docker-env -s 192.168.10 -w poolnet -c pgdemo -n 3
    
    INFO -- The network poolnet already exists. Using subnet 172.28.0 associated with poolnet and ignoring 192.168.10
    
    The following file: DockerRunThis.pgdemo,  contains the needed docker run commands

As you can see, it ignored your custom subnet and used the one already associated with the **poolnet** network

It also assigns the next available IP's from the subnet to your containers

If you were to looks at the DockerRunThis file, you would see the following in it

    docker run -p 6434:5432 -p 9994:9999 --env=PGPASSWORD=postgres -v pgdemo1-pgdata:/pgdata --hostname=pgdemo1 --network=poolnet --name=pgdemo1 --privileged --ip 172.28.0.14  -dt rocky9_pg17_pgpool
    docker run -p 6435:5432 -p 9995:9999 --env=PGPASSWORD=postgres -v pgdemo2-pgdata:/pgdata --hostname=pgdemo2 --network=poolnet --name=pgdemo2 --privileged --ip 172.28.0.15  -dt rocky9_pg17_pgpool
    docker run -p 6436:5432 -p 9996:9999 --env=PGPASSWORD=postgres -v pgdemo3-pgdata:/pgdata --hostname=pgdemo3 --network=poolnet --name=pgdemo3 --privileged --ip 172.28.0.16  -dt rocky9_pg17_pgpool

Notice the ip's assigned to your new containers.  That is because the existing container on the poolnet network have ip's assigned already.


    d7e53402587c   2d2845e69ba1   "/bin/bash -c /entry…"   9 days ago   Up 34 hours   22/tcp, 80/tcp, 443/tcp, 9898/tcp, 0.0.0.0:6432->5432/tcp, [::]:6432->5432/tcp, 0.0.0.0:9992->9999/tcp, [::]:9992->9999/tcp   pg2
    caa606de2612   2d2845e69ba1   "/bin/bash -c /entry…"   9 days ago   Up 34 hours   22/tcp, 80/tcp, 443/tcp, 9898/tcp, 0.0.0.0:6431->5432/tcp, [::]:6431->5432/tcp, 0.0.0.0:9991->9999/tcp, [::]:9991->9999/tcp   pg1

A docker network inspect of of the pool net


    docker network inspect poolnet --format '{{range .Containers}}{{.Name}} - {{.IPv4Address}}{{"\n"}}{{end}}'

Shows us the ip's already in use

    docker network inspect poolnet --format '{{range .Containers}}{{.Name}} - {{.IPv4Address}}{{"\n"}}{{end}}'
    pg1 - 172.28.0.11/16
    pg2 - 172.28.0.12/16


And as you can see a few lines up, our pgdemo containers start with ip of **172.28.0.14**  We could modify the script to start at 13, but I wanted a buffer in there




## The DockerRunThis file. Whats in it?

The following is the file we generated to manage our docker deploy. It is pretty simple and straight forward. Remember, you get a custom file for every container name.


    #!/bin/bash
    
    
    function runNetwork() {
            docker network create --driver bridge --subnet 192.168.10.0/24 --gateway 192.168.10.1 pgdemonet 
    }
    
    
    function runContainers() {
            runNetwork
            docker run -p 6434:5432 -p 9994:9999 --env=PGPASSWORD=postgres -v pgdemo1-pgdata:/pgdata --hostname=pgdemo1 --network=pgdemonet --name=pgdemo1 --privileged --ip 192.168.10.11  -dt rocky9_pg17_pgpool 
            docker run -p 6435:5432 -p 9995:9999 --env=PGPASSWORD=postgres -v pgdemo2-pgdata:/pgdata --hostname=pgdemo2 --network=pgdemonet --name=pgdemo2 --privileged --ip 192.168.10.12  -dt rocky9_pg17_pgpool 
            docker run -p 6436:5432 -p 9996:9999 --env=PGPASSWORD=postgres -v pgdemo3-pgdata:/pgdata --hostname=pgdemo3 --network=pgdemonet --name=pgdemo3 --privileged --ip 192.168.10.13  -dt rocky9_pg17_pgpool 
    }
    
    
    function stopContainers() {
            docker stop  pgdemo1 pgdemo2 pgdemo3
    }
    
    
    function startContainers() {
            docker start  pgdemo1 pgdemo2 pgdemo3
    }
    
    
    function removeContainers() {
            docker rm  pgdemo1 pgdemo2 pgdemo3
    }
    
    
    function removeNetwork() {
            docker network rm pgdemonet
    }
    
    
    function removeVolumes() {
            docker volume rm   pgdemo1-pgdata  pgdemo2-pgdata  pgdemo3-pgdata
    }
    
    
    function deleteEnv() {
            stopContainers
            removeContainers
            removeNetwork
            if [ $force -eq 1 ]; then
                    removeVolumes
            fi
    }
    
    
    function usage() {
            echo -e "Usage:"
            echo -e "$0 [OPTION]"
            echo -e "       -a OPTIONS [start stop run rm rmvolumes delete createnetwork] "
            echo -e "       -f force the delete of volumes. Otherwise, they are preserved"
            exit 
    }
    
    
    force=0
    doThis=""
    
    while getopts a:f name
    do
       case $name in
          a) doThis="$OPTARG";;
          f) force=1;;
          *) usage;;
          ?) usage;;
       esac
    done
    shift $(($OPTIND - 1))
    
    
    
    
    case $doThis in
       "start") startContainers;;  
       "stop") stopContainers;;  
       "run") runContainers;;  
       "rm") removeContainers;;  
       "rmvolumes") removeVolumes;;  
       "createnetwork") createNetwork;;  
       "delete") deleteEnv;;  
       *) usage;;
       ?) usage;;
    esac 

