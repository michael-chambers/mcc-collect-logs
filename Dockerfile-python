FROM ubuntu/python3:k8s
RUN apt update
RUN apt upgrade -y
RUN apt install -y wget vim magic-wormhole
RUN wget https://binary.mirantis.com/releases/get_container_cloud.sh -O /tmp/get_container_cloud.sh
RUN chmod 0755 /tmp/get_container_cloud.sh
RUN /tmp/get_container_cloud.sh
COPY collection.sh /collection.sh
COPY collect_logs.py /collect_logs.py
ENTRYPOINT ["/usr/bin/python3", "/collect_logs.py"]