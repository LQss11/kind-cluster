# kind-cluster
Create and Test on a Kubernetes cluster with kind
# Quick start
To create a cluster you can either run the following script making sure you have kubectl and go installed on your machine, code of installation is available in the **Dockerfile**, then you can run the following:
```sh
docker compose up --build -d
# Export kubeconfig to host
docker cp cluster-generator:/root/.kube/config .
# Export env vars (windows)
$env:KUBECONFIG="$PWD/config/config"
# Export env vars (linux)
KUBECONFIG="$(pwd)/config/config"

kubectl get nodes -o wide

# Pull image inside cluster
docker exec -it cluster-generator bash -c "docker pull nginx && kind load docker-image --name k8s-cluster nginx" 
kubectl apply -f example
kubectl port-forward --namespace default deploy/nginx 3000:80 --address 0.0.0.0

# To export image to cluster
kind load docker-image --name k8s-cluster alpine
kubectl port-forward --namespace myorg-monitoring deploy/grafana 3000:3000 --address 0.0.0.0
# Test example
helm repo add groundcover https://helm.groundcover.com/
helm repo update
helm install caretta --namespace caretta --create-namespace groundcover/caretta
kubectl get all -n caretta

kubectl port-forward --namespace caretta deploy/caretta-grafana 3000:3000 --address 0.0.0.0
```


[for more ](https://pkg.go.dev/sigs.k8s.io/kind/pkg/apis/config/v1alpha4)