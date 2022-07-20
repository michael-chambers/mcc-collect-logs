from email.policy import default
from importlib.metadata import metadata
from kubernetes import client, config

config.load_kube_config("/Users/mchambers/Documents/SRE-197/kubeconfig-container-cloud-kaas-bootstrap.yml")

# v1 = client.CoreV1Api()
# #thing = v1.get_api_resources()
# #print("Listing pods with their IPs:")
# ret = v1.list_pod_for_all_namespaces(watch=False)
# for i in ret.items:
#     print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))

api_client = client.CustomObjectsApi()
thingy = api_client.list_cluster_custom_object(group="cluster.k8s.io", version="v1alpha1", plural="clusters")
y = 0
for x in thingy['items']:
    clusterString = x['metadata']['name']
    if clusterString == "kaas-mgmt":
        y = y+1
print(len(thingy['items']))
print(y)
# thingyList = list(thingy.items())
# items = thingyList[1]
# clusters = items[1]
# myCluster = clusters[0]
# myClusterMeta = myCluster.items(metadata)
