# Download Kubectl binaries
FROM ubuntu:20.04
ARG ARCH=amd64

RUN apt-get update && apt-get install -y  bash curl wget iputils-ping net-tools



WORKDIR /usr/local/bin
# Download Kubernetes release
ARG KUBERNETES_RELEASE=v1.21.1
RUN wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/${ARCH}/kubectl -O kubectl\
    && chmod +x kubectl

# Download Kind release
# https://github.com/kubernetes-sigs/kind/releases 
ARG KIND_RELEASE=v0.11.1
RUN wget https://github.com/kubernetes-sigs/kind/releases/download/${KIND_RELEASE}/kind-linux-${ARCH} -O kind \
    && chmod +x kind

WORKDIR /root/.kind
COPY cluster-setup.sh /root/.kind/cluster-setup.sh
COPY convert-kubeconfig.sh /root/.kind/convert-kubeconfig.sh

RUN chmod 777 /root/.kind/cluster-setup.sh
RUN chmod 777 /root/.kind/convert-kubeconfig.sh

CMD ["bash"]