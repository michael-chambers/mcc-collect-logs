FROM ubuntu:latest
RUN apt update
RUN apt upgrade -y
RUN apt install -y wget vim magic-wormhole
RUN apt install -y apt-transport-https ca-certificates curl
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt update
RUN apt install -y kubectl
RUN wget https://binary.mirantis.com/releases/get_container_cloud.sh -O /tmp/get_container_cloud.sh
RUN chmod 0755 /tmp/get_container_cloud.sh
RUN /tmp/get_container_cloud.sh
COPY collect_logs.sh /collect_logs.sh
ENTRYPOINT ["/bin/sh", "-c", "/collect_logs.sh"]