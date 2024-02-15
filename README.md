# kind-cluster
Create and Test on a Kubernetes cluster with kind
# Quick start
To create a cluster you can either run the following script making sure you have kubectl and go installed on your machine, code of installation is available in the **Dockerfile**, then you can run the following:
```sh
docker compose up --build -d
# Export kubeconfig to host (make sure to update server host to localhost)
# If server host different from localhost you will need to ignore ca and add (insecure-skip-tls-verify: true)
docker cp cluster-generator:/root/.kube/config ./config
# Export env vars (windows)
$env:KUBECONFIG="$PWD/config/config"
# Export env vars (linux)
KUBECONFIG="$(pwd)/config/config"
# Check cluster nodes
kubectl get nodes -o wide

# Get cluster name 
docker exec -it cluster-generator bash -c "kind get clusters"
```

# Deploy and access
Since apiserver address is **0.0.0.0** you can access the exposed ports from anywhere
```sh
# Load image inside cluster
kubectl create deployment nginx --image nginx:alpine
kubectl port-forward --namespace default deploy/nginx 9922:80 --address 0.0.0.0 # Visit localhost:9922
```

# Manage images
```sh
# Load image inside cluster (kind load docker-image --name k8s-cluster alpine)
docker exec -it cluster-generator bash -c "docker pull nginx && kind load docker-image --name k8s-cluster nginx" 
```

# Helm
```sh
# Example helm grafana cluster chart
helm repo add groundcover https://helm.groundcover.com/
helm repo update
helm install caretta --namespace caretta --create-namespace groundcover/caretta
kubectl get all -n caretta
kubectl port-forward --namespace caretta deploy/caretta-grafana 3000:3000 --address 0.0.0.0
```

# Plugins
In this example I have installed some kubectl plugins as well as some helm plugins:
```sh
# Visit: https://krew.sigs.k8s.io/plugins/
# kubectl get pod PODNAME -o yaml | kubectl neat
# kubectl access-matrix for deployment
# kubectl node-shell k8s-cluster-worker
kubectl krew info cost
kubectl plugin list
kubectl krew install 
```

# More information
[for more ](https://pkg.go.dev/sigs.k8s.io/kind/pkg/apis/config/v1alpha4)