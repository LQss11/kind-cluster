#!/bin/bash
export HOST=localhost
cp /root/.kube/config /root/.kube/oldconfig
docker cp k8s-cluster-control-plane:/etc/kubernetes/admin.conf /root/.kube/config
PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "6443/tcp") 0).HostPort}}' k8s-cluster-control-plane)
sed -i "s#server:.*#server: https://$HOST:$PORT#g" /root/.kube/config
