#!/bin/bash
source .env

CONTAINER_ID=""

while getopts ":i:" opt; do
  case ${opt} in
    i )
      CONTAINER_ID=$OPTARG
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    : )
      echo "Invalid option: -$OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done

# If no container id is given, exit the script
if [ -z "$CONTAINER_ID" ]; then
    echo "No container ID provided. Use -i <container_id> to specify a container."
    exit 1
fi

# Query the database for the backup details
backup_info=$(mysql --user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST $DB_DATABASE \
    -e "SELECT container_name, image, volume_name, s3_path FROM backups WHERE container_id = '$CONTAINER_ID';")

# Split the backup_info into its components
read container_name image volume_name s3_path <<<$(echo $backup_info)

# Download the volume from S3
aws s3 cp $s3_path ./

# Unzip the volume backup
tar -xzvf $volume_name.tar.gz -C /var/lib/docker/volumes/

# Spin up the container again
docker run --name $container_name --volume /var/lib/docker/volumes/$volume_name:/your/container/volume/path $image

echo "Container $container_name recovered and started."
