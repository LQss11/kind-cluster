#!/bin/bash

# Create initial cluster config template
cat >kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
EOF

# Regular exp not between 1 and 9
re='^[1-9]+$'

# Select how many manager and worker nodes
# to be in the kind cluster
# 1 control-plane and 1 worker for minimal test
while read -p "How many manager nodes do you need in the cluster?:" manager; do
    if ! [[ $manager =~ $re ]]; then
        echo "error: Not a valid number" >&2
        exit 1
    fi
    for i in $(seq 1 $manager); do
        # Ask for the range of ports to be opened
        read -p "Enter the range of ports to open for control-plane node $i (e.g., 3000-4000, leave blank for no extra ports): " portRange
        # Validate the input ports
        if [[ $portRange =~ ^[1-9][0-9]*-[1-9][0-9]*$ ]]; then
            IFS='-' read -ra portRangeParts <<< "$portRange"
            startPort=${portRangeParts[0]}
            endPort=${portRangeParts[1]}
            cat >>kind-config.yaml <<EOF
- role: control-plane
  extraPortMappings:
EOF
            for port in $(seq $startPort $endPort); do
                cat >>kind-config.yaml <<EOF
  - containerPort: $port
    hostPort: $port
    listenAddress: "0.0.0.0"
    protocol: tcp
EOF
            done
        else
            cat >>kind-config.yaml <<EOF
- role: control-plane
EOF
        fi
    done
    break
done

while read -p "How many worker nodes do you need in the cluster?:" worker; do
    if ! [[ $worker =~ $re ]]; then
        echo "error: Not a valid number" >&2
        exit 1
    fi
    for i in $(seq 1 $worker); do
        echo - role: worker >>kind-config.yaml
    done
    break
done

echo "############################################################################"
echo "$manager control-plane and $worker worker nodes will be joining the cluster"
echo "############################################################################"

# Create the cluster
kind create cluster --name k8s-cluster --config kind-config.yaml

# Update the k8s server api host+port depending on
# haproxy loadbalancerr or single control-plane
if [[ $manager == 1 ]]; then
    kubectl config set clusters.kind-k8s-cluster.server https://k8s-cluster-control-plane:6443
else
    kubectl config set clusters.kind-k8s-cluster.server https://k8s-cluster-external-load-balancer:6443
fi
