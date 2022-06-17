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


# Final docker dind (alpine) image content
FROM jenkins/jenkins:lts as runtime 
# Maven version argument 
# Could be passed through --build-arg or .env file or directly from docker compose
ARG MAVEN_V
# working with root user
USER root

# Copy kind binaries
COPY --from=kubectl-kind /usr/local/bin/kind /bin/kind
# Copy kubectl binaries
COPY --from=kubectl-kind /usr/local/bin/kubectl /bin/kubectl

#MAKE SURE THAT THE BUILD CONTEXT IS RIGHT

# Copy necessary directories
COPY /cluster/content /content
# Copy jenkins init scripts
COPY /jenkins/jenkins-scripts/ /usr/share/jenkins/ref/init.groovy.d/

# Install init plugins
RUN jenkins-plugin-cli --plugins docker-workflow cloudbees-folder timestamper \
ws-cleanup pipeline-stage-view pam-auth pipeline-github-lib \
matrix-auth ssh build-timeout github-branch-source  ssh-slaves \
email-ext antisamy-markup-formatter workflow-aggregator git ldap authorize-project

# install wget + curl
RUN apt-get update && apt-get install -y wget curl

# Download maven binaries
RUN wget --no-verbose -O /tmp/apache-maven-$MAVEN_V-bin.tar.gz http://apache.cs.utah.edu/maven/maven-3/$MAVEN_V/binaries/apache-maven-$MAVEN_V-bin.tar.gz
# install maven
RUN tar xzf /tmp/apache-maven-$MAVEN_V-bin.tar.gz -C /opt/ \
    && ln -s /opt/apache-maven-$MAVEN_V /opt/maven \
    && ln -s /opt/maven/bin/mvn /usr/local/bin \
    && rm -f /tmp/apache-maven-$MAVEN_V-bin.tar.gz

# Give Jenkins user permission to use mvn properly
RUN chown -R jenkins:jenkins /opt/maven

# Remove Cache
RUN rm -rf /var/cache/apt/*

# Run entrypoint script and additional commands if needed
#CMD [ "sh","-c","/usr/local/bin/jenkins.sh && sh"]

# Skip install plugins wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
# Setup maven home
ENV MAVEN_HOME /opt/maven    
# JAVA mem heap size
ENV JAVA_OPTS -Xms2g -Xmx3g


# For the nexus server setup
COPY /jenkins/settings.xml /opt/apache-maven-$MAVEN_V/conf/settings.xml

VOLUME /var/jenkins_home

# PS > To use host unix docker socket we need root
USER jenkins