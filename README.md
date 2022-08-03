# Collect Logs container

## Where to find
Currently the container is available on Docker Hub as [varlite/mcc-collect-logs](https://hub.docker.com/r/varlite/mcc-collect-logs). It is currently available for both AMD64 and ARM64 architecture.

## What's included
The container is based on the official Docker image of Ubuntu, with the following software installed:
- kaas-boostrap ([available from Mirantis](https://binary.mirantis.com/releases/get_container_cloud.sh))
- kubectl
- wget
- vim
- magic-wormhole

`kaas-bootstrap` contains the `container-cloud` utility, which can perform several functions including bootstrapping a new MCC cluster. The focus here is the `container-cloud collect logs` function.

## How to use
First gather the following files:
- Kubeconfig file for the MCC management cluster
- Private SSH key for the cluster being examined
- Kubeconfig file for the cluster being examined (if different from the management cluster)

Place these files in a folder on your local computer, then run the container in interactive mode and mount the folder into the container at runtime:

```sh
docker run -it -v /full/path/to/folder:/some/path varlite/mcc-collect-logs:latest
```

### Overview
The container will present a series of prompts, as follows:
1. **Kubeconfig for the MCC Management Cluster (path)** - provide the full or relative path to the MCC management cluster kubeconfig file in your mounted folder
	1. _The script will use kubectl to contact the management cluster and determine its name by finding the cluster.k8s.io custom resource (CR) in the default namespace, if multiple CRs are found in the default namespace, a numbered list of their names will be provided to the user with the prompt:_ **Please specify the Management cluster (#)**. - indicate the desired cluster by number
2. **Private key file for the cluster for which you want logs (path)** - provide the full or relative path to the private SSH key file in your mounted folder
3. _The script will now display a numbered list of all cluster.k8s.io CRs found on the management cluster with the prompt:_ **Please specify the cluster you want to collect logs for (#)** - indicate the desired cluster by number
4. _The script will now display the selected cluster name and its MCC project (namespace)_
	1. _If the selected cluster is not the management cluster, a prompt will now appear:_ **Specified cluster is not the Management cluster, please specify the cluster Kubeconfig file (path)** - provide the full or relative path to the cluster kubeconfig file in your mounted folder
5. _The script will now attempt to collect the logs for the indicated cluster. This can take a while._
6. _The logs are compressed using_ `tar`
7. _The logs are readied for transport via magic-wormhole. A code to receive the data will be displayed, which can be input on your local machine (provided magic-wormhole is installed)._