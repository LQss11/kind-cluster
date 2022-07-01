# kind-cluster
Create and Test on a Kubernetes cluster with kind
# Quick start
To create a cluster you can either run the following script making sure you have kubectl and go installed on your machine, code of installation is available in the **Dockerfile**, then you can run the following:
```sh
./cluster-setup.sh
```
# Docker-compose
## Create cluster
If you want to start and manage your cluster (useful for Windows users) you can run the following using docker-compose:
```sh
docker-compose up -d --build 
```
then you can run the script inside the container:
```sh
docker exec -it cluster-generator bash -c "./cluster-setup.sh"
```
## Delete cluster
```sh
docker exec -it cluster-generator bash -c "kind delete cluster --name k8s-cluster"
```
## Run kubectl commands from cluster generator
That container must belong to the same network of the cluster created:
```sh
docker network connect kind cluster-generator
```
### Copy kubeconfig
you can run kubectl from ur host machine on the created cluster by importing kubeconfig:
```sh
docker exec -it cluster-generator bash -c "./convert-kubeconfig.sh"
docker cp cluster-generator:/root/.kube/kindconfig ./
kubectl get all --kubeconfig ./kindconfig
```

### Cluster management
You can run commands and check files of cluster by getting in the master node:
```sh
# Get the name of master
docker exec -it cluster-generator bash -c "cat /root/.kube/config  | grep server | cut -d/ -f3 | cut -d: -f1"
docker exec -it <master-container> bash 
```

