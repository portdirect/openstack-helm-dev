#!/bin/bash
OS_PROJECT=admin
openstack quota set ${OS_PROJECT} --cores "$(($(grep -c ^processor /proc/cpuinfo) * 2))"
openstack quota set ${OS_PROJECT} --ram "$(($(($(awk '/^MemTotal/ { print $(NF-1) }' /proc/meminfo) / 1024)) - 8192 ))"
openstack quota set ${OS_PROJECT} --instances 64
openstack quota set ${OS_PROJECT} --secgroups 128
openstack quota set ${OS_PROJECT} --floating-ips 256
openstack quota set ${OS_PROJECT} --ports -1
openstack quota set ${OS_PROJECT} --networks 128
openstack quota set ${OS_PROJECT} --subnets 256
openstack quota set ${OS_PROJECT} --routers 64
openstack quota show ${OS_PROJECT}
