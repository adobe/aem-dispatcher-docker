#
# Copyright (c) 2023 Adobe Systems Incorporated. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM --platform=$TARGETPLATFORM centos:7

#install HTTPD
RUN yum -y update
RUN yum -y install httpd mod_ssl procps haproxy iputils tree telnet

#remove default CentOS config
RUN rm -rf /etc/httpd/conf/*
RUN rm -rf /etc/httpd/conf.d/*
RUN rm -rf /etc/httpd/conf.modules.d/*

#Copy the AMS base files into the image.
COPY ams/2.6/etc/httpd /etc/httpd
RUN mkdir /etc/httpd/conf.d/enabled_vhosts
RUN ln -s /etc/httpd/conf.d/available_vhosts/aem_author.vhost /etc/httpd/conf.d/enabled_vhosts/aem_author.vhost
RUN ln -s /etc/httpd/conf.d/available_vhosts/aem_flush_author.vhost /etc/httpd/conf.d/enabled_vhosts/aem_flush_author.vhost
RUN ln -s /etc/httpd/conf.d/available_vhosts/aem_publish.vhost /etc/httpd/conf.d/enabled_vhosts/aem_publish.vhost
RUN ln -s /etc/httpd/conf.d/available_vhosts/aem_flush.vhost /etc/httpd/conf.d/enabled_vhosts/aem_flush.vhost
RUN ln -s /etc/httpd/conf.d/available_vhosts/aem_health.vhost /etc/httpd/conf.d/enabled_vhosts/aem_health.vhost

RUN mkdir /etc/httpd/conf.dispatcher.d/enabled_farms
RUN ln -s /etc/httpd/conf.dispatcher.d/available_farms/000_ams_catchall_farm.any /etc/httpd/conf.dispatcher.d/enabled_farms/000_ams_catchall_farm.any
RUN ln -s /etc/httpd/conf.dispatcher.d/available_farms/001_ams_author_flush_farm.any /etc/httpd/conf.dispatcher.d/enabled_farms/001_ams_author_flush_farm.any
RUN ln -s /etc/httpd/conf.dispatcher.d/available_farms/001_ams_publish_flush_farm.any /etc/httpd/conf.dispatcher.d/enabled_farms/001_ams_publish_flush_farm.any
RUN ln -s /etc/httpd/conf.dispatcher.d/available_farms/002_ams_author_farm.any /etc/httpd/conf.dispatcher.d/enabled_farms/002_ams_author_farm.any
RUN ln -s /etc/httpd/conf.dispatcher.d/available_farms/002_ams_publish_farm.any /etc/httpd/conf.dispatcher.d/enabled_farms/002_ams_publish_farm.any

# Install dispatcher
ARG TARGETARCH
COPY scripts/setup.sh /
RUN chmod +x /setup.sh
RUN ./setup.sh
RUN rm /setup.sh

# Create default docroots
RUN mkdir -p /mnt/var/www/html
RUN chown apache:apache /mnt/var/www/html

RUN mkdir -p /mnt/var/www/default
RUN chown apache:apache /mnt/var/www/default

RUN mkdir -p /mnt/var/www/author
RUN chown apache:apache /mnt/var/www/author

# Setup SSL
RUN mkdir -p /etc/ssl/docker && \
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=GB/ST=London/L=London/O=Adobe/CN=localhost" \
     -keyout /etc/ssl/docker/localhost.key \
     -out /etc/ssl/docker/localhost.crt && \
    cat /etc/ssl/docker/localhost.key /etc/ssl/docker/localhost.crt > /etc/ssl/docker/haproxy.pem

COPY haproxy/haproxy.cfg /etc/haproxy

COPY scripts/launch.sh /
RUN chmod +x /launch.sh

COPY LICENSE /
COPY NOTICE /

EXPOSE  80 443

# Start container
ENTRYPOINT ["/bin/bash","/launch.sh"]
