#
# Copyright (c) 2024 Adobe Systems Incorporated. All rights reserved.
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
DISP_ID=docker
## Replace value with the Author IP and Port you are using:
AUTHOR_IP=host.docker.internal
AUTHOR_PORT=4502
AUTHOR_DEFAULT_HOSTNAME=author.docker.local
AUTHOR_DOCROOT=/mnt/var/www/author
## Replace value with the Publisher IP and Port you are using:
PUBLISH_IP=host.docker.internal
PUBLISH_PORT=4503
PUBLISH_DEFAULT_HOSTNAME=publish.docker.local
PUBLISH_DOCROOT=/mnt/var/www/html
## Replace value with the LiveCycle IP and Port you are using:
LIVECYCLE_IP=127.0.0.1
LIVECYCLE_PORT=8080
LIVECYCLE_DEFAULT_HOSTNAME=aemforms-exampleco-dev.adobecqms.net
LIVECYCLE_DOCROOT=/mnt/var/www/lc

PUBLISH_FORCE_SSL=0
AUTHOR_FORCE_SSL=0

## Enable / Disable CRXDE access.  Production this should be disabled
#CRX_FILTER=allow
CRX_FILTER=deny

## Allow dispatcher flush from any IP
## WARNING: Set this to "allowed" on local dev environments that don't have fixed IPs
## Set to deny or comment out on prod environments
DISPATCHER_FLUSH_FROM_ANYWHERE=allow

ENV_TYPE=dev
RUNMODE=sites
