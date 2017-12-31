#!/bin/bash

OSH_DIR=/opt/openstack-helm

OSH_INFRA_DIR=/opt/openstack-helm-infra

(cd ${OSH_DIR} && ./tools/deployment/developer/02-setup-client.sh)

helm install ${OSH_DIR}/ingress \
  --namespace=openstack \
  --name=ingress

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install --namespace=ceph ${OSH_DIR}/ceph --name=ceph \
    --set endpoints.identity.namespace=openstack \
    --set endpoints.object_store.namespace=ceph \
    --set endpoints.ceph_mon.namespace=ceph \
    --set ceph.rgw_keystone_auth=true \
    --set network.public=$(cat /etc/openstack-helm/storage-subnet) \
    --set network.cluster=$(cat /etc/openstack-helm/storage-subnet) \
    --set deployment.storage_secrets=true \
    --set deployment.ceph=true \
    --set deployment.rbd_provisioner=true \
    --set deployment.client_secrets=false \
    --set deployment.rgw_keystone_user_and_endpoints=false \
    --set bootstrap.enabled=true

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh ceph 1200)

helm install --namespace=openstack ${OSH_DIR}/ceph --name=ceph-openstack-config \
    --set endpoints.identity.namespace=openstack \
    --set endpoints.object_store.namespace=ceph \
    --set endpoints.ceph_mon.namespace=ceph \
    --set ceph.rgw_keystone_auth=true \
    --set network.public=$(cat /etc/openstack-helm/storage-subnet) \
    --set network.cluster=$(cat /etc/openstack-helm/storage-subnet) \
    --set deployment.storage_secrets=false \
    --set deployment.ceph=false \
    --set deployment.rbd_provisioner=false \
    --set deployment.client_secrets=true \
    --set deployment.rgw_keystone_user_and_endpoints=false

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_INFRA_DIR}/nfs-provisioner \
  --name=prometheus-nfs \
  --namespace=openstack \
  --set storage.type=persistentVolumeClaim

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_INFRA_DIR}/prometheus \
  --name=prometheus \
  --namespace=openstack \
  --set pod.replicas.prometheus=2 \
  --set storage.storage_class=prometheus-nfs

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_INFRA_DIR}/prometheus-kube-state-metrics \
  --namespace=kube-system \
  --name=prometheus-kube-state-metrics

helm install ${OSH_INFRA_DIR}/prometheus-node-exporter \
  --namespace=kube-system \
  --name=prometheus-node-exporter

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh kube-system)

helm install ${OSH_INFRA_DIR}/prometheus-alertmanager \
  --name=prometheus-alertmanager \
  --namespace=openstack \
  --set pod.replicas.alertmanager=2 \
  --set storage.storage_class=prometheus-nfs

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_INFRA_DIR}/grafana \
    --namespace=openstack \
    --name=grafana \
    --set pod.replicas.grafana=2

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_INFRA_DIR}/elasticsearch \
    --namespace=openstack \
    --name=elasticsearch \
    --set storage.filesystem_repository.storage_class=prometheus-nfs

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_INFRA_DIR}/fluent-logging \
    --namespace=openstack \
    --name=fluent-logging \
    --set pod.replicas.fluentd=2

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_INFRA_DIR}/kibana \
    --namespace=openstack \
    --name=kibana \
    --set pod.replicas.kibana=2

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

(cd ${OSH_DIR} && git fetch https://git.openstack.org/openstack/openstack-helm refs/changes/22/531622/2 && git checkout FETCH_HEAD)
helm install ${OSH_DIR}/mariadb \
    --namespace=openstack \
    --name=mariadb

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack 1200)

helm install ${OSH_DIR}/rabbitmq \
    --namespace=openstack \
    --name=rabbitmq
helm install ${OSH_DIR}/memcached \
    --namespace=openstack \
    --name=memcached

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_DIR}/keystone \
    --namespace=openstack \
    --name=keystone \
    --set pod.replicas.api=2

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_INFRA_DIR}/prometheus-openstack-exporter \
    --namespace=openstack \
    --name=prometheus-openstack-exporter

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install --namespace=openstack ${OSH_DIR}/ceph --name=radosgw-openstack \
   --set endpoints.identity.namespace=openstack \
   --set endpoints.object_store.namespace=ceph \
   --set endpoints.ceph_mon.namespace=ceph \
   --set ceph.rgw_keystone_auth=true \
   --set network.public=$(cat /etc/openstack-helm/storage-subnet) \
   --set network.cluster=$(cat /etc/openstack-helm/storage-subnet) \
   --set deployment.storage_secrets=false \
   --set deployment.ceph=false \
   --set deployment.rbd_provisioner=false \
   --set deployment.client_secrets=false \
   --set deployment.rgw_keystone_user_and_endpoints=true

helm install ${OSH_DIR}/horizon \
   --namespace=openstack \
   --name=horizon \
   --set pod.replicas.server=2 \
   --set network.node_port.enabled=true \
   --set network.node_port.port=31000

helm install ${OSH_DIR}/heat \
   --namespace=openstack \
   --name=heat \
   --set pod.replicas.api=2 \
   --set pod.replicas.cfn=2 \
   --set pod.replicas.cloudwatch=2 \
   --set pod.replicas.engine=2

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

GLANCE_BACKEND="radosgw" # NOTE(portdirect), this could be: radosgw, rbd, swift or pvc
helm install ${OSH_DIR}/glance \
  --namespace=openstack \
  --name=glance \
  --set pod.replicas.api=2 \
  --set pod.replicas.registry=2 \
  --set storage=${GLANCE_BACKEND}

helm install ${OSH_DIR}/openvswitch \
  --namespace=openstack \
  --name=openvswitch

helm install ${OSH_DIR}/libvirt \
  --namespace=openstack \
  --name=libvirt

helm install ${OSH_DIR}/cinder \
  --namespace=openstack \
  --name=cinder \
  --set pod.replicas.api=2 \
  --set pod.replicas.volume=1 \
  --set pod.replicas.scheduler=1 \
  --set pod.replicas.backup=1 \
  --set conf.cinder.DEFAULT.backup_driver=cinder.backup.drivers.swift

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

helm install ${OSH_DIR}/nova \
    --namespace=openstack \
    --name=nova \
    --set pod.replicas.api_metadata=1 \
    --set pod.replicas.placement=2 \
    --set pod.replicas.osapi=2 \
    --set pod.replicas.conductor=2 \
    --set pod.replicas.consoleauth=2 \
    --set pod.replicas.scheduler=2 \
    --set pod.replicas.novncproxy=1 \
    --set labels.api_metadata.node_selector_key=openstack-helm-node-class \
    --set labels.api_metadata.node_selector_value=primary

helm install ${OSH_DIR}/neutron \
    --namespace=openstack \
    --name=neutron \
    --set pod.replicas.server=2 \
    --values=./tools/overrides/mvp/neutron-ovs.yaml \
    --set labels.agent.dhcp.node_selector_key=openstack-helm-node-class \
    --set labels.agent.dhcp.node_selector_value=primary \
    --set labels.agent.l3.node_selector_key=openstack-helm-node-class \
    --set labels.agent.l3.node_selector_value=primary \
    --set labels.agent.metadata.node_selector_key=openstack-helm-node-class \
    --set labels.agent.metadata.node_selector_value=primary

(cd ${OSH_DIR} && ./tools/deployment/developer/wait-for-pods.sh openstack)

# helm install ${OSH_DIR}/postgresql \
# --namespace=openstack \
# --name=postgresql
# helm install ${OSH_DIR}/gnocchi \
# --namespace=openstack \
# --name=gnocchi
# --set pod.replicas.api=2
# helm install ${OSH_DIR}/mongodb \
# --namespace=openstack \
# --name=mongodb
# helm install ${OSH_DIR}/ceilometer \
# --namespace=openstack
# --name=ceilometer \
# --set pod.replicas.api=2 \
# --set pod.replicas.central=2 \
# --set pod.replicas.collector=2 \
# --set pod.replicas.notification=2
