import subprocess
from subprocess import Popen
from concurrent.futures import process
from optparse import Option
from kubernetes import client, config
import readline
import subprocess
import os

# these settings allow for tab-completing file paths
readline.set_completer_delims(' \t\n=')
readline.parse_and_bind("tab: complete")

# get the kubeconfig file for the MCC management cluster
mgmtKubeconfig = input("Kubeconfig for the MCC Management Cluster (path): ")
mgmtKubeconfig = os.path.realpath(mgmtKubeconfig)
config.load_kube_config(mgmtKubeconfig)

# check if there is more than one cluster in the default namespace
# if there is, ask the user which one is the the management cluster
custom_api_client = client.CustomObjectsApi()
defaultClusters = custom_api_client.list_namespaced_custom_object(group="cluster.k8s.io", version="v1alpha1", namespace="default",plural="clusters")
if len(defaultClusters['items']) > 1:
  mgmtClusterName = input("Multiple clusters detected in MCC's default namespace, please specify the name of the Management cluster: ")
else:
  mgmtClusterName = defaultClusters['items'][0]['metadata']['name']
print("The selected management cluster is " + mgmtClusterName)

# gather cluster private key
privateKey = input("Private key file for the cluster for which you want logs (path): ")
privateKey = os.path.realpath(privateKey)

# gather cluster name and determine cluster namespace
# clusterName = input("Cluster for which you want logs (name): ")
allClusters = custom_api_client.list_cluster_custom_object(group="cluster.k8s.io", version="v1alpha1", plural="clusters")
y = 1
print("The following clusters were detected:")
for x in allClusters['items']:
  nameString = x['metadata']['name']
  print(y, "\t", nameString)
  y = y + 1

# display the clusters found in MCC and let the user decide from a list
# then automatically find the namespace (MCC project) of the chosen cluster
i = input("Please specify the cluster you want to collect logs for (#): ")
clusterName = allClusters['items'][int(i) - 1]['metadata']['name']
clusterNamespace = allClusters['items'][int(i) - 1]['metadata']['namespace']
print("The selected cluster is " + clusterName)
print("The selected cluster is located in the " + clusterNamespace + " project")

if mgmtClusterName != clusterName:
  clusterKubeconfig = input("Specified cluster is not the Management cluster, please specify the cluster Kubeconfig file (path): ")
  clusterKubeconfig = os.path.realpath(clusterKubeconfig)

print("############ BEGINNING LOG COLLECTION FOR CLUSTER " + clusterName + " ############")
try:
  clusterKubeconfig
except NameError:
  # if clusterKubeconfig is not defined, then we're dealing with the MCC management cluster, collect logs
  print("Collecting logs on MCC Management cluster: " + clusterName)
  collectLogs = subprocess.Popen(['/kaas-bootstrap/container-cloud', 'collect', 'logs', '--management-kubeconfig', mgmtKubeconfig, '--key-file', privateKey, '--cluster-name', clusterName, '--cluster-namespace', clusterNamespace, '--output-dir', '/logs'])
  collectLogs.wait()
else:
  # if clusterKubeconfig is defined, then we're dealing with a regional or managed cluster, collect logs
  print("Collecting logs on Regional/Managed cluster: " + clusterName)
  collectLogs = subprocess.Popen(['/kaas-bootstrap/container-cloud', 'collect', 'logs', '--management-kubeconfig', mgmtKubeconfig, '--key-file', privateKey, '--kubeconfig', clusterKubeconfig, '--cluster-name', clusterName, '--cluster-namespace', clusterNamespace, '--output-dir', '/logs'])
  collectLogs.wait()
# compress and send out logs via wormhole
print("compressing logs")
os.system("tar -zcvf logs.tgz /logs")
os.system("wormhole send logs.tgz")