#!/bin/bash

function listClusters() {
  clusters=("$@")
  y=1
  for x in "${clusters[@]}"
  do
    echo -e $y'\t'$x
    let y++
  done
}

#KUBECTL_PATH=/kaas-bootstrap/bin/kubectl

# collect parameters for log collection script

# start with gathering information about the MCC Management Cluster
read -e -p "Kubeconfig for the MCC Management Cluster (path): " MGMT_KUBECONFIG
MGMT_KUBECONFIG=$(realpath $MGMT_KUBECONFIG)
DEFAULT_CLUSTERS=$(kubectl --kubeconfig $MGMT_KUBECONFIG --namespace default get cluster -o=jsonpath={'.items[*].metadata.name'})
DEFAULT_CLUSTERS=($DEFAULT_CLUSTERS)
if ((${#DEFAULT_CLUSTERS[@]} > 1))
then
  echo "Multiple clusters deteced in MCC's default namespace"
  listClusters "${DEFAULT_CLUSTERS[@]}"
  read -p "Please specify the Management cluster (#): " MGMT_CLUSTER_NUMBER
  MGMT_CLUSTER_NAME=${DEFAULT_CLUSTERS[$MGMT_CLUSTER_NUMBER - 1]}
else
  MGMT_CLUSTER_NAME=$(kubectl --kubeconfig $MGMT_KUBECONFIG --namespace default get cluster -o=jsonpath={'.items[0].metadata.name'})
fi
echo "The selected management cluster is:" $MGMT_CLUSTER_NAME

# gather cluster private key
read -e -p "Private key file for the cluster for which you want logs (path): " PRIVATE_KEY
PRIVATE_KEY=$(realpath $PRIVATE_KEY)

# gather cluster name and determine cluster namespace
# read -p "Cluster for which you want logs (name): " CLUSTER_NAME
ALL_CLUSTERS=$(kubectl --kubeconfig $MGMT_KUBECONFIG get cluster --all-namespaces -o=jsonpath={'.items[*].metadata.name'})
ALL_CLUSTERS=($ALL_CLUSTERS)
# if ((${#ALL_CLUSTERS[@]} > 1))
# then
  # read -p "Multiple clusters detected named $CLUSTER_NAME, please specify the namespace of your cluster: " CLUSTER_NAMESPACE
listClusters "${ALL_CLUSTERS[@]}"
read -p "Please specify the Management cluster (#): " CLUSTER_NUMBER
CLUSTER_NAME=${ALL_CLUSTERS[$CLUSTER_NUMBER - 1]}
CLUSTER_NAMESPACE=$(kubectl --kubeconfig $MGMT_KUBECONFIG get cluster --all-namespaces -o=jsonpath={'.items[?(@.metadata.name=="'$CLUSTER_NAME'")].metadata.namespace'})
echo "The selected cluster is" $CLUSTER_NAME
echo "The selected cluster is located in the" $CLUSTER_NAMESPACE "project"

# maybe this or the namespace could be figured out from the kubectl
if [[ $MGMT_CLUSTER_NAME != $CLUSTER_NAME ]]
then
    read -e -p "Specified cluster is not the Management cluster, please specify the cluster Kubeconfig file (path): " CLUSTER_KUBECONFIG
fi

# collect logs
echo "############ BEGINNING LOG COLLECTION FOR CLUSTER " $CLUSTER_NAME " ############"
if [[ -z ${CLUSTER_KUBECONFIG} ]]
  /kaas-bootstrap/container-cloud collect logs --management-kubeconfig $MGMT_KUBECONFIG --key-file $PRIVATE_KEY --kubeconfig $CLUSTER_KUBECONFIG --cluster-name $CLUSTER_NAME --cluster-namespace $CLUSTER_NAMESPACE --output-dir /logs
else
  /kaas-bootstrap/container-cloud collect logs --management-kubeconfig $MGMT_KUBECONFIG --key-file $PRIVATE_KEY --cluster-name $CLUSTER_NAME --cluster-namespace $CLUSTER_NAMESPACE --output-dir /logs
fi
# docker run mcc-diags/collect-logs:latest -e $MGMT_KUBECONFIG -e $PRIVATE_KEY -e $CLUSTER_NAME -e $CLUSTER_KUBECONFIG -e $CLUSTER_NAMESPACE
echo "compressing logs"
tar -zcvf logs.tgz /logs
wormhole send logs.tgz