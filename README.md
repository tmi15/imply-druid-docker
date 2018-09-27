# imply-druid-docker
Imply Druid Docker cluster

- This repository contains the required configuration to build the Imply Druid docker images in both standalone (non-clustered) or Cluster versions.
- This has been tested with Imply Druid Distrubution version 2.7.1 and 2.7.5.
- This has been tested on Google Cloud Platform (GCP) and uses GCP native services like Google Cloud Storage (GCS) buckets, CloudSQL (Postgres) and Google Kuberenetes Engine (GKE).
- Druid deep-storage (data and indexing logs) is configured to GCS.
- Druid meta-storage is configured to CloudSQL (Postgres) for both Druid cluster and Imply UI (Pivot).
- It uses the standalone Zookeeper cluster created on GKE.
- Monitoring and Logging is enabled by default to StackDriver.
- Also tested data migration from 2.7.1 to 2.7.5, just change the image version and it upgrades seemlessly.
- Auto-scaling of the Druid Cluster is configured as Horizontal Pod Autoscaling which will create more pods based on CPU Usage.


## Commands used to build the docker image
```
docker build -t imply-cluster:2.7.5 .
docker tag ca74ec87905b tmi15/imply-cluster:2.7.5
docker push tmi15/imply-cluster:2.7.5
```

## Commands below have been tested on GCP
Following commands were executed/tested on GCloud Shell directly


## Create Druid GKE cluster
```
gcloud container clusters create "cluster-druid" \
--zone "europe-west2-a" --username "admin" \
--cluster-version "1.10.7-gke.2" \
--machine-type "n1-highmem-8" --image-type "COS" \
--disk-type "pd-standard" --disk-size "100" \
--scopes bigquery,logging-write,monitoring-write,\
service-management,compute-rw,storage-rw,monitoring,\
pubsub,service-control,service-management,sql-admin,\
trace,cloud-platform --num-nodes "3" --min-nodes "1" \
--max-nodes "3" --enable-cloud-logging --enable-cloud-monitoring \
--addons HorizontalPodAutoscaling,HttpLoadBalancing,KubernetesDashboard \
--no-enable-autoupgrade --enable-autorepair
```

## Create the GCS Bucket
```
gsutil mb -c multi_regional -l eu gs://imply-druid-poc-bucket
```

## Create the CloudSQL Postgres DB
```
gcloud sql instances create druid-poc --cpu=1 --memory=3840MiB \
--database-version=POSTGRES_9_6 --region europe-west2 \
--storage-auto-increase --availability-type=REGIONAL

gcloud sql users set-password postgres no-host --instance=druid-poc \
--password=druid-poc

gcloud sql users create druid-poc --instance=druid-poc --password=druid-poc

gcloud sql databases create druid --instance=druid-poc

gcloud sql databases create pivot --instance=druid-poc

```

## Create Zookeeper statefulset (used by Druid cluster)
```
kubectl --cluster gke_gcp-sky-analytics-poc_europe-west2-a_cluster-druid apply -f zookeeper.yaml
```

## Create Druid pod
```
kubectl --cluster gke_gcp-sky-analytics-poc_europe-west2-a_cluster-druid apply -f druid.yaml
```
