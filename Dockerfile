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
RUN yum -y update && yum -y install httpd mod_ssl procps haproxy iputils tree telnet && yum clean all

#remove default CentOS config
RUN rm -rf /etc/httpd/conf/* && rm -rf /etc/httpd/conf.d/* && rm -rf /etc/httpd/conf.modules.d/*

#Copy the AMS base files into the image.
COPY ams/2.6/etc/httpd /etc/httpd
COPY haproxy/haproxy.cfg /etc/haproxy

# Install dispatcher
ARG TARGETARCH
COPY scripts/setup.sh /
RUN chmod +x /setup.sh
# ensuring correct file ending on windows systems
RUN sed -i -e 's/\r$//' /setup.sh
RUN ./setup.sh
RUN rm /setup.sh


COPY scripts/launch.sh /
# ensuring correct file ending on windows systems
RUN sed -i -e 's/\r$//' /launch.sh
RUN chmod +x /launch.sh

COPY LICENSE /
COPY NOTICE /

EXPOSE  80 443

# Start container
ENTRYPOINT ["/bin/bash","/launch.sh"]
