
# Dispatcher Docker image

This is a simple dispatcher image that is very close to an AMS setup.
It builds on top of [centos7](https://hub.docker.com/_/centos/) since the AMS dispatcher is build on top of Redhat Enterprise Linux 7.7 and contains the default Dispatcher 2.6 configuration.

The default publish host has been set to `localhost` and the default renderer is set to `host.docker.internal:4503` which should point to AEM instance running on your local computer.

[HAProxy](https://www.haproxy.org/) has been embedded in the image to support SSL connections the mimic how AMS has setup their ELBs/AppGWs.

Environmental variables are configured in `scripts/env.sh`

# Basic Setup

## Building the image

We use docker's buildx to support multi-arch images.

```shell
docker buildx create --use
docker buildx build --load -t dispatcher --platform=linux/amd64 .
```

To build for Apple M1/M2, use `--platform=linux/arm64` instead

Multi-arch images can be built, but can only be pushed to a remote registry and not be directly loaded in Docker desktop.

## Checking the created image

```shell
$ docker images
REPOSITORY   TAG      IMAGE ID       CREATED        SIZE
dispatcher   latest   6b4b91a23c06   1 minute ago   725MB
```

## How to use the image

You can run the image in two different ways

1. As a completely independent remote server
   - This is a quick and dirty way to get dispatcher up and running locally and you're not planning to make any changes to the configuration files.
2. By keeping the configuration files on your local system and mounting them when you start the image.
   - This is the recommended way to start the image as it will allow you to quickly make changes and see them apply without the need to rebuild the container.

### Running the image - Quick and dirty

```shell
docker run -p 80:8080 -p 443:8443 -itd --rm --env-file scripts/env.sh --name dispatcher dispatcher
```

| Quick Reference   |                                                              |
| ----------------- | ------------------------------------------------------------ |
| -p 80:8080        | map port 80 of the host to port 8080 of the container use -p 8080:8080 if port 80 already is in use on the host) |
| -p 443:8443       | map port 443 of the host  to port 8443 of the container. (use -p 4443:8443 if port 443 already is in use on the host) |
| -i                | keep STDIN open even if not attached ("interactive") and     |
| -t                | allocate a pseudo-tty to allow interactive logins ("tty")    |
| -d                | run docker detached in the background                        |
| --rm              | automatically remove the container when it exits             |
| --env-file        | Environment file to bind to the container                    |
| --name dispatcher | assign name "dispatcher" to the container, consider setting a different name per project.                   |

## Checking the container's current state

```shell
$ docker container ps
CONTAINER ID   IMAGE        COMMAND                  CREATED              STATUS              PORTS                                                          NAMES
8c345d523ff2   dispatcher   "/bin/bash /launch.sh"   About a minute ago   Up About a minute   80/tcp, 443/tcp, 0.0.0.0:80->8080/tcp, 0.0.0.0:443->8443/tcp   dispatcher
```

## Testing your AEM installation

The dispatcher maps `publish.docker.local` to the local publisher instance on port 4503. Run the publisher and

navigate to [http://publish.docker.local/content/we-retail/language-masters/en.html](http://publish.docker.local/content/we-retail/language-masters/en.html)

## Adapting your localhost

The configuration is based on the configuration used by AMS. If you are planning to deploy the configuration into AMS, please make sure to also read the section on **Immutable files**.

As for now, it suffices to understand, that the configuration is environment agnostic. That means, it is supposed to run locally, on dev, stage and prod without any change. All environment specific variables are stored in a file `scripts/env.sh`.

The inital configuration this setup is using

`author.docker.local` for the Author

`publish.docker.local`for the Publisher

The Dispatcher connects to the Author and Publisher through `host.docker.internal` .

Make sure that both are mapped in your local `/etc/hosts` file.

```shell
$ cat /etc/hosts | grep docker.local
127.0.0.1 author.docker.local
127.0.0.1 publish.docker.local
127.0.0.1 host.docker.internal
```

# Using your own dispatcher config

There are several options to use this container with your own configuration:

1. Remote web server ([dispatcher-remote](dispatcher-remote))
   - Copy the configuration you are working on into the container with `docker cp`
   - Log into the container and restart apache
   - A disadvantage with `docker cp` is that it only copies and does not sync the directory contents and will require manual intervention if files were deleted locally.
2. Mount a local directory ([dispatcher-mount](dispatcher-mount))
   - A local dispatcher project module is mounted read-only into the container at startup.
   - After each change, restart the current container or SIGHUP the httpd process.
3. Create a separate docker image
   - This is useful if you have a separate team working on multiple dispatcher configurations and you have access to a container repository to distribute pre-built images

## Remote web server

### Start dispatcher in container

```shell
docker run -p 80:8080 -p 443:8443 -itd --rm --name dispatcher --env-file scripts/env.sh dispatcher 
```

### Copy files to docker container

```shell
cd _your_project_/dispatcher/etc/httpd
docker cp . dispatcher:/etc/httpd/
```

### Connecting to the Dispatcher (à la SSH)

You can run shell inside the dispatcher container. This is the equivalent of connecting to dispatcher via SSH

```shell
docker exec -it dispatcher /bin/bash
```

### Reloading the Dispatcher

You can reload the dispatcher with following command:

```shell
kill -HUP `cat /run/httpd/httpd.pid`
```

### Inspecting the logs

While connected to dispatcher, you can view the logs in `/var/log/httpd`

```shell
$ ll /var/log/httpd/
total 36
-rw-r--r-- 1 root root 14779 May 20 10:04 access_log
-rw-r--r-- 1 root root 15295 May 20 10:04 dispatcher.log
-rw-r--r-- 1 root root   739 May 20 10:03 error_log
-rw-r--r-- 1 root root     0 May 20 10:03 healthcheck_access_log
```

## Mount a local directory

### Start Dispatcher with local folders mapped  

We are assuming you have your Dispatcher configuration stored in a folder "dispatcher" in your project:

```shell
cd _your_project_/dispatcher
mkdir logs

docker run -p 80:8080 -p 443:8443 -itd --rm --name dispatcher --env-file scripts/env.sh \
  --mount type=bind,src=$(pwd)/src/conf,dst=/etc/httpd/conf,readonly=true \
  --mount type=bind,src=$(pwd)/src/conf.d,dst=/etc/httpd/conf.d,readonly=true \
  --mount type=bind,src=$(pwd)/src/conf.dispatcher.d,dst=/etc/httpd/conf.dispatcher.d,readonly=true \
  --mount type=bind,src=$(pwd)/src/conf.modules.d,dst=/etc/httpd/conf.modules.d,readonly=true \
  --mount type=bind,src=$(pwd)/logs,dst=/var/log/httpd \
  --mount type=tmpfs,dst=/tmp \
  dispatcher
```

| Quick Reference |                                          |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| --mount type=bind,src=$(pwd)/src/conf,dst=/etc/httpd/conf,readonly=true | Binds the folder `src/conf` in the host's current working directory to /etc/httpd/conf in a read-only fashion |
| --mount type=tmpfs,dst=/tmp                                  | Uses a memory based filesystem for temporary data to (slighly) improve the performance |

This is a lot to type. We had to mount each folder individually, as the Dispatcher Docker image also contains the `/modules`  folder in `/etc` and mounting `/etc`would make them unavailable.

Alternatively, you can use the convenience script

```shell
./dispatcher-mount
```

in this distribution. The script assumes that the "src/conf" folder is in the current directory and terminates with an error if it can't find it.

## Restarting the container

You can restart the container by calling

```shell
docker restart -t0 dispatcher
```

| Quick Reference |                                                              |
| --------------- | ------------------------------------------------------------ |
| -t0             | Kills the container after 0 seconds and does not wait for the Apache to shut down. This is safe, as the container does not preserve any crucial data. |

Or - if you are lazy - just call the shell-scripts:

```shell
./dispatcher-kill 
./dispatcher-mount
```

# Create your own image

You can also use this image as a base image, and add your configuration on top of it with similar Dockerfile

```Dockerfile
FROM dispatcher

COPY yourproject/dispatcher/src/conf /etc/httpd
COPY yourproject/dispatcher/src/conf.d /etc/httpd
COPY yourproject/dispatcher/src/conf.dispatcher.d /etc/httpd
COPY yourproject/dispatcher/src/conf.modules.d /etc/httpd
COPY yourproject/dispatcher/cert.pem /etc/ssl/docker/haproxy.pem 

# Start container
ENTRYPOINT ["/bin/bash","/launch.sh"]
```

# Immutable files

Certain files in AMS are immuatable, and cannot be changed. This is achieved on filesystem level by using extended attributes. Docker does not support such functionality which means that any changes to the dispatcher configuration will be reflected in your docker image, but may not be applied on an AMS environment after deployment.

Those files are:

```text
|-- conf/
|   `-- httpd.conf
|-- conf.d/
|   |-- available_vhosts/
|   |   |-- 000_unhealthy_author.vhost
|   |   |-- 000_unhealthy_publish.vhost
|   |   |-- aem_author.vhost
|   |   |-- aem_flush.vhost
|   |   |-- aem_health.vhost
|   |   |-- aem_lc.vhost
|   |   `-- aem_publish.vhost
|   |-- dispatcher_vhost.conf
|   |-- logformat.conf
|   |-- rewrites/
|   |   |-- base_rewrite.rules
|   |   `-- xforwarded_forcessl_rewrite.rules
|   |-- security.conf
|   `-- whitelists/
|       `-- 000_base_whitelist.rules
|-- conf.dispatcher.d/
|   |-- available_farms/
|   |   |-- 000_ams_author_farm.any
|   |   |-- 001_ams_lc_farm.any
|   |   `-- 999_ams_publish_farm.any
|   |-- cache/
|   |   |-- ams_author_cache.any
|   |   |-- ams_author_invalidate_allowed.any
|   |   |-- ams_publish_cache.any
|   |   `-- ams_publish_invalidate_allowed.any
|   |-- clientheaders/
|   |   |-- ams_author_clientheaders.any
|   |   |-- ams_common_clientheaders.any
|   |   |-- ams_lc_clientheaders.any
|   |   `-- ams_publish_clientheaders.any
|   |-- dispatcher.any
|   |-- filters/
|   |   |-- ams_author_filters.any
|   |   |-- ams_lc_filters.any
|   |   `-- ams_publish_filters.any
|   |-- renders/
|   |   |-- ams_author_renders.any
|   |   |-- ams_lc_renders.any
|   |   `-- ams_publish_renders.any
|   `-- vhosts/
|       |-- ams_author_vhosts.any
|       |-- ams_lc_vhosts.any
|       `-- ams_publish_vhosts.any
`-- conf.modules.d/
    `-- 02-dispatcher.conf
```

# Troubleshooting

## Inspecting log files

By default, the `DISP_LOG_LEVEL` is set to "4" (trace) in the file `ams_default.vars` (This setting is used in `dispatcher_vhost.conf`).

Log into the remote dispatcher and view the log files call

```shell
./dispatcher-login
```

and navigate into `/var/log/httpd/`

```shell
cd /var/log/httpd/
```

> **TIP** If you mounted the logs directory, you can just inspect the logs files directly on your machine.
