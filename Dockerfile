# Download Kubectl binaries
FROM docker:dind
ARG ARCH=amd64

RUN apk add bash curl wget iputils-ping net-tools kubectx helm git go
# RUN apt-get update && apt-get install -y  bash curl wget iputils-ping net-tools



WORKDIR /usr/local/bin
# Download Kubernetes release
ARG KUBERNETES_RELEASE=v1.27.3
RUN wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_RELEASE}/bin/linux/${ARCH}/kubectl -O kubectl\
    && chmod +x kubectl

# Download Kind release
# https://github.com/kubernetes-sigs/kind/releases 
ARG KIND_RELEASE=v0.20.0
RUN wget https://github.com/kubernetes-sigs/kind/releases/download/${KIND_RELEASE}/kind-linux-${ARCH} -O kind \
    && chmod +x kind

ARG WORKDIR
WORKDIR ${WORKDIR}
COPY . .

RUN chmod 777 entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]