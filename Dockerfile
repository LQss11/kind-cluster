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

# Install Krew
RUN set -x && \
    cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf "${KREW}.tar.gz" && \
    ./"${KREW}" install krew

# Add Krew to the PATH
ENV PATH="${PATH}:/root/.krew/bin"
# Install kubernetes plugins
RUN kubectl krew install access-matrix cost count dds deprecations doctor \
example explore get-all images karmada neat node-shell ns open-svc permissions popeye

# Install Helm plugins
RUN helm plugin install https://github.com/komodorio/helm-dashboard && \
    helm plugin install https://github.com/nikhilsbhat/helm-drift && \
    helm plugin install https://github.com/databus23/helm-diff

ARG WORKDIR
WORKDIR ${WORKDIR}
COPY . .

RUN chmod 777 entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]