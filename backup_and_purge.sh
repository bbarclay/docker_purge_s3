#!/bin/bash
source .env

REMOVE_IMAGES=false

while getopts "r" option; do
  case $option in
    r)
      REMOVE_IMAGES=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Get the list of all containers older than 15 days
containers=$(docker ps -a --filter "status=exited" --filter "status=paused" --format "{{.ID}} {{.CreatedAt}}" | \
  while read id date time zone; do
    container_date=$(date -d "$date $time $zone" +%s)
    if (( $(date +%s) - container_date >= 15*24*60*60 )); then
      echo $id
    fi
  done)

# Backup and purge each container and its volumes
for container in $containers; do
  # Get container info
  name=$(docker inspect -f '{{.Name}}' $container)
  image=$(docker inspect -f '{{.Config.Image}}' $container)
  volumes=$(docker inspect -f '{{range .Mounts}}{{println .Source}}{{end}}' $container)
  status=$(docker inspect -f '{{.State.Status}}' $container)

  # If the container is paused, stop it first
  if [ "$status" = "paused" ]; then
    docker stop $container
  fi

  # Create a backup for each volume
  for volume in $volumes; do
    volume_name=$(basename $volume)
    backup_name=$volume_name-$(date +%Y%m%d%H%M%S).tar.gz

    # Backup the volume
    tar -czvf $backup_name $volume

    # Upload the backup to S3
    aws s3 cp $backup_name s3://$S3_BUCKET_NAME/$backup_name

    # Store backup details in the database
    mysql --user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST $DB_DATABASE \
      -e "INSERT INTO backups (container_id, container_name, image, volume_name, s3_path) \
          VALUES ('$container', '$name', '$image', '$volume_name', 's3://$S3_BUCKET_NAME/$backup_name');"

    # Purge the volume
    docker volume rm $volume_name
  done

  # Purge the container
  docker rm $container

  # Remove the image if the -r or --remove-images option was provided
  if [ "$REMOVE_IMAGES" = true ]; then
    docker rmi $image
  fi

done
