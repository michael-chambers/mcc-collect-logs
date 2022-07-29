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

# get the kubeconfig file for the MCC management cluster
read -e -p "Kubeconfig for the MCC Management Cluster (path): " MGMT_KUBECONFIG
MGMT_KUBECONFIG=$(realpath $MGMT_KUBECONFIG)

# check if there is more than one cluster in the default namespace
# if there is, ask the user which one is the the management cluster
DEFAULT_CLUSTERS=$(kubectl --kubeconfig $MGMT_KUBECONFIG --namespace default get cluster -o=jsonpath={'.items[*].metadata.name'})
DEFAULT_CLUSTERS=($DEFAULT_CLUSTERS)
if ((${#DEFAULT_CLUSTERS[@]} > 1))
then
  echo "Multiple clusters deteced in MCC's default namespace"
  listClusters "${DEFAULT_CLUSTERS[@]}"
  read -p "Please specify the cluster you want to collect logs for (#): " MGMT_CLUSTER_NUMBER
  MGMT_CLUSTER_NAME=${DEFAULT_CLUSTERS[$MGMT_CLUSTER_NUMBER - 1]}
else
  MGMT_CLUSTER_NAME=$(kubectl --kubeconfig $MGMT_KUBECONFIG --namespace default get cluster -o=jsonpath={'.items[0].metadata.name'})
fi
echo "The selected management cluster is:" $MGMT_CLUSTER_NAME

# gather cluster private key
read -e -p "Private key file for the cluster for which you want logs (path): " PRIVATE_KEY
PRIVATE_KEY=$(realpath $PRIVATE_KEY)

# display the clusters found in MCC and let the user decide from a list
# then automatically find the namespace (MCC project) of the chosen cluster
ALL_CLUSTERS=$(kubectl --kubeconfig $MGMT_KUBECONFIG get cluster --all-namespaces -o=jsonpath={'.items[*].metadata.name'})
ALL_CLUSTERS=($ALL_CLUSTERS)
echo "The following clusters were detected:"
listClusters "${ALL_CLUSTERS[@]}"
read -p "Please specify the Management cluster (#): " CLUSTER_NUMBER
CLUSTER_NAME=${ALL_CLUSTERS[$CLUSTER_NUMBER - 1]}
CLUSTER_NAMESPACE=$(kubectl --kubeconfig $MGMT_KUBECONFIG get cluster --all-namespaces -o=jsonpath={'.items[?(@.metadata.name=="'$CLUSTER_NAME'")].metadata.namespace'})
echo "The selected cluster is" $CLUSTER_NAME
echo "The selected cluster is located in the" $CLUSTER_NAMESPACE "project"

# ask for cluster kubeconfig file if needed
if [[ $MGMT_CLUSTER_NAME != $CLUSTER_NAME ]]
then
    read -e -p "Specified cluster is not the Management cluster, please specify the cluster Kubeconfig file (path): " CLUSTER_KUBECONFIG
fi

# collect logs
echo "############ BEGINNING LOG COLLECTION FOR CLUSTER " $CLUSTER_NAME " ############"
if [[ -z ${CLUSTER_KUBECONFIG} ]]
then
  echo "Collecting logs on MCC Management cluster:" $CLUSTER_NAME
  # if CLUSTER_KUBECONFIG is not defined, then we're dealing with the MCC management cluster, collect logs
  /kaas-bootstrap/container-cloud collect logs --management-kubeconfig $MGMT_KUBECONFIG --key-file $PRIVATE_KEY --cluster-name $CLUSTER_NAME --cluster-namespace $CLUSTER_NAMESPACE --output-dir /logs
else
  # if CLUSTER_KUBECONFIG is defined, then we're dealing with a regional or managed cluster, collect logs
  echo "Collecting logs on Regional/Managed cluster:" $CLUSTER_NAME
  /kaas-bootstrap/container-cloud collect logs --management-kubeconfig $MGMT_KUBECONFIG --key-file $PRIVATE_KEY --kubeconfig $CLUSTER_KUBECONFIG --cluster-name $CLUSTER_NAME --cluster-namespace $CLUSTER_NAMESPACE --output-dir /logs
fi

# compress and send out logs via wormhole
echo "compressing logs"
tar -zcvf logs.tgz /logs
wormhole send logs.tgz