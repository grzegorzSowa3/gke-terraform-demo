rm target/deployment.yml
sed -e "s+{{GCLOUD_PROJECT_ID}}+$1+g" -e "s+{{IMAGE_VERSION}}+$2+g" deployment.yml >> target/deployment.yml