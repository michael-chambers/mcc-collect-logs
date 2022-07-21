#!/bin/bash

#KUBECTL_PATH=/kaas-bootstrap/bin/kubectl

# collect parameters for log collection script

# start with gathering information about the MCC Management Cluster
read -e -p "Kubeconfig for the MCC Management Cluster (path): " MGMT_KUBECONFIG
MGMT_KUBECONFIG=$(realpath $MGMT_KUBECONFIG)
DEFAULT_CLUSTERS=$(kubectl --kubeconfig $MGMT_KUBECONFIG --namespace default get cluster -o=jsonpath={'.items[*].metadata.name'})
DEFAULT_CLUSTERS=($DEFAULT_CLUSTERS)
if ((${#DEFAULT_CLUSTERS[@]} > 1))
then
  read -p "Multiple clusters detected in MCC's Default namespace, please specify the name of the Management cluster: " MGMT_CLUSTER_NAME
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
y=1
for x in ${ALL_CLUSTERS[@]}
do
  echo -e $y'\t'$x
  let y++
done
read -p "Please specify the Management cluster (#): " CLUSTER_NUMBER
CLUSTER_NAME=${ALL_CLUSTERS[$CLUSTER_NUMBER - 1]}
CLUSTER_NAMESPACE=$(kubectl --kubeconfig $MGMT_KUBECONFIG get cluster --all-namespaces -o=jsonpath={'.items[?(@.metadata.name=="'$CLUSTER_NAME'")].metadata.namespace'})
echo "The selected cluster is" $CLUSTER_NAME
echo "The selected cluster is located in the" $CLUSTER_NAMESPACE "project"
# else
#   MGMT_CLUSTER_NAME = ${ALL_CLUSTERS[0]}
#   CLUSTER_NAMESPACE=$(kubectl --kubeconfig $MGMT_KUBECONFIG get cluster --all-namespaces -o=jsonpath={'.items[?(@.metadata.name=="'$CLUSTER_NAME'")].metadata.namespace'})
# fi
echo "The cluster's namespace is:" $CLUSTER_NAMESPACE

# maybe this or the namespace could be figured out from the kubectl
if [[ $MGMT_CLUSTER_NAME != $CLUSTER_NAME ]]
then
    read -e -p "Specified cluster is not the Management cluster, please specify the cluster Kubeconfig file (path): " CLUSTER_KUBECONFIG
fi

# collect logs
echo "############ BEGINNING LOG COLLECTION FOR CLUSTER " $CLUSTER_NAME " ############"
#/kaas-bootstrap/container-cloud collect logs --management-kubeconfig $MGMT_KUBECONFIG --key-file $PRIVATE_KEY --kubeconfig $CLUSTER_KUBECONFIG --cluster-name $CLUSTER_NAME --cluster-namespace $CLUSTER_NAMESPACE --output-dir /logs
docker run mcc-diags/collect-logs:latest -e $MGMT_KUBECONFIG -e $PRIVATE_KEY -e $CLUSTER_NAME -e $CLUSTER_KUBECONFIG -e $CLUSTER_NAMESPACE