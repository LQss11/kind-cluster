# kind-cluster
Create and Test on a Kubernetes cluster with kind
# Quick start
To create a cluster you can either run the following script making sure you have kubectl and go installed on your machine, code of installation is available in the **Dockerfile**, then you can run the following:
```sh
docker compose up --build -d
docker exec -it cluster-generator bash -c "./cluster-setup.sh"
docker exec -it cluster-generator bash -c "./convert-kubeconfig.sh"
docker exec -it cluster-generator bash
kubectl get all

# Test example
helm repo add groundcover https://helm.groundcover.com/
helm repo update
helm install caretta --namespace caretta --create-namespace groundcover/caretta
kubectl get all -n caretta

docker exec -it k8s-cluster-control-plane bash
kubectl port-forward --namespace caretta deploy/caretta-grafana 3000:3000 --address 0.0.0.0
```
