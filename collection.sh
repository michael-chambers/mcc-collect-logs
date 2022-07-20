#!/bin/sh
ls -l /user-files
if [ -f "/user-files/cluster.yml" ]
then
  echo "Collecting logs on Regional/Managed cluster"
  echo "Cluster name is" $CLUSTER_NAME
  echo "Cluster namespace is" $CLUSTER_NAMESPACE
  /kaas-bootstrap/container-cloud collect logs --management-kubeconfig /user-files/mgmtKubeconfig.yml --key-file /user-files/private_key --kubeconfig /user-files/cluster.yml --cluster-name $CLUSTER_NAME --cluster-namespace $CLUSTER_NAMESPACE --output-dir /logs
else
  echo "Collecting logs on MCC Management cluster"
  echo "Cluster name is" $CLUSTER_NAME
  echo "Cluster namespace is" $CLUSTER_NAMESPACE
  /kaas-bootstrap/container-cloud collect logs --management-kubeconfig /user-files/mgmtKubeconfig.yml --key-file /user-files/private_key --cluster-name $CLUSTER_NAME --cluster-namespace $CLUSTER_NAMESPACE --output-dir /logs
fi
echo "compressing logs"
tar -zcvf logs.tgz /logs
wormhole send logs.tgz