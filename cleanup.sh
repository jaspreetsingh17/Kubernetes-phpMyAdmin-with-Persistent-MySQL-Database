#!/bin/bash

# Cleanup Script for phpMyAdmin, MySQL and MinIO Kubernetes Deployment

echo "=== Cleaning up phpMyAdmin, MySQL and MinIO Deployment ==="

# Delete phpMyAdmin
echo -e "\n[1/9] Deleting phpMyAdmin Service..."
kubectl delete -f phpmyadmin-service.yaml

echo -e "\n[2/9] Deleting phpMyAdmin Deployment..."
kubectl delete -f phpmyadmin-deployment.yaml

# Delete MinIO
echo -e "\n[3/9] Deleting MinIO Services..."
kubectl delete -f minio-service.yaml

echo -e "\n[4/9] Deleting MinIO StatefulSet..."
kubectl delete -f minio-statefulset.yaml

echo -e "\n[5/9] Deleting MinIO PVC..."
kubectl delete pvc minio-data-minio-0

# Delete MySQL
echo -e "\n[6/9] Deleting MySQL Service..."
kubectl delete -f mysql-service.yaml

echo -e "\n[7/9] Deleting MySQL StatefulSet..."
kubectl delete -f mysql-statefulset.yaml

# Delete StatefulSet PVC (created automatically by StatefulSet)
echo -e "\n[8/9] Deleting MySQL PVC..."
kubectl delete pvc mysql-data-mysql-0

# Delete Persistent Volumes
echo -e "\n[9/9] Deleting Persistent Volumes..."
kubectl delete -f mysql-pv.yaml
kubectl delete -f minio-pv.yaml

# Delete Secrets
kubectl delete secret mysql-secrets
kubectl delete secret minio-secrets

echo -e "\n=== Cleanup Complete ==="
echo "All resources have been deleted!"

# Show remaining resources
echo -e "\n=== Remaining Resources ==="
kubectl get all
kubectl get pv,pvc
