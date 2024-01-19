#!/bin/bash

# Log function for better formatting
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')]: $1"
}

# Function to check if Docker is running
check_docker_running() {
    docker info &> /dev/null
}

# Function to start Docker if not already running
start_docker() {
    log "Checking Docker status..."
    if ! check_docker_running; then
        log "Docker is not running. Starting Docker..."
        # Redirect stdin and stdout for dockerd-entrypoint.sh
        exec 3>&1 4>&2
        dockerd-entrypoint.sh 1>&3 2>&4 &

        # Close the duplicated file descriptors
        exec 3>&- 4>&-

        sleep 10  # Give Docker some time to start
        if ! check_docker_running; then
            log "Error: Docker did not start successfully."
            exit 1
        fi
        log "Docker started successfully."
    else
        log "Docker is already running."
    fi
}


# Function to check if a Docker container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^$1$"
}

# Function to create a kind cluster configuration
create_kind_config() {
    log "Creating initial cluster config template..."
    cat >kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: ${APISERVER_URL}
  apiServerPort: ${APISERVER_PORT}
nodes:
EOF

    # Manager nodes
    while true; do
        if [ -z "$MANAGER_NODES" ]; then
            read -p "How many manager nodes do you need in the cluster?:" manager
        else
            manager="$MANAGER_NODES"
        fi

        # ... (rest of your existing manager nodes logic)

        if ! [[ $manager =~ $re ]]; then
            echo "error: Not a valid number" >&2
            exit 1
        fi

    for i in $(seq 1 $manager); do
        # Ask for the range of ports to be opened
        if [ -z "$PORT_RANGE" ]; then
            read -p "Enter the range of ports to open for control-plane node $i (e.g., 3000-4000, leave blank for no extra ports): " portRange
        else
            portRange="$PORT_RANGE"
        fi

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


# Worker nodes
while true; do
    if [ -z "$WORKER_NODES" ]; then
        read -p "How many worker nodes do you need in the cluster?:" worker
    else
        worker="$WORKER_NODES"
    fi

    if ! [[ $worker =~ $re ]]; then
        echo "error: Not a valid number" >&2
        exit 1
    fi

    for i in $(seq 1 $worker); do
        echo - role: worker >>kind-config.yaml
    done
    break
done

log "Cluster config template created successfully."
echo "############################################################################"
echo "$MANAGER_NODES control-plane and $WORKER_NODES worker nodes will be joining the cluster"
echo "############################################################################"
rm -rf /root/.kube/*
# Create the cluster
log "Started Creating cluster."
kind create cluster --name k8s-cluster --config kind-config.yaml

# Update the k8s server api host+port depending on
# haproxy loadbalancer or single control-plane
if [[ $MANAGER_NODES == 1 ]]; then
    kubectl config set clusters.kind-k8s-cluster.server https://k8s-cluster-control-plane:6443
else
    kubectl config set clusters.kind-k8s-cluster.server https://k8s-cluster-external-load-balancer:6443
fi

log "Importing kubeconfig on dind."
HOST=localhost
cp /root/.kube/config /root/.kube/oldconfig
docker cp k8s-cluster-control-plane:/etc/kubernetes/admin.conf /root/.kube/config
PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "6443/tcp") 0).HostPort}}' k8s-cluster-control-plane)
sed -i "s#server:.*#server: https://$HOST:$PORT#g" /root/.kube/config

}

# Main script starts here

# Start Docker
start_docker

# Check if Docker is accessible
if ! check_docker_running; then
    log "Error: Docker is not running or not accessible."
    exit 1
fi

# Check if Portainer container already exists
if container_exists "portainer"; then
    log "Portainer container already exists."
    docker stop portainer
    docker rm portainer
    docker volume rm portainer_data

fi

log "Starting Portainer container..."
rm -rf /tmp/portainer_password
echo -n ${PORTAINER_PASSWORD} > /tmp/portainer_password
chmod 777 /tmp/portainer_password
docker run -d -p 8000:8000 -p ${PORTAINER_PORT}:9000 \
    --name=portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    -v /tmp/portainer_password:/tmp/portainer_password \
    portainer/portainer-ce:latest -H unix:///var/run/docker.sock --admin-password-file /tmp/portainer_password

if [ "$CLUSTER_BOOTSTRAP" -eq 1 ]; then
    create_kind_config
fi

log "Script completed successfully."

wait