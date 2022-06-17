# Download Kubectl binaries
FROM alpine AS kubectl-kind
ARG ARCH=amd64

WORKDIR /usr/local/bin
# Download Kubernetes release
ARG KUBERNETES_RELEASE=v1.23.3
RUN wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/${ARCH}/kubectl -O kubectl\
    && chmod +x kubectl

# Download Kind release
# https://github.com/kubernetes-sigs/kind/releases 
ARG KIND_RELEASE=v0.11.1
RUN wget https://github.com/kubernetes-sigs/kind/releases/download/${KIND_RELEASE}/kind-linux-${ARCH} -O kind \
    && chmod +x kind

RUN apk add bash curl
WORKDIR /root/.kind
COPY  cluster-setup.sh /root/.kind/cluster-setup.sh