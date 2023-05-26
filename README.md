# Docker Container Backup and Purge

#Warning, I have not tested this yet. Please test it in a none production environment before fully deploying.

This repository contains two bash scripts to backup and purge Docker containers and their associated volumes. The scripts also have the option to remove the Docker images.

The scripts use the Docker, AWS CLI, and MySQL CLI commands to perform their tasks. They interact with Amazon S3 for storing backups and MySQL for storing backup metadata.

## Prerequisites

- Docker
- AWS CLI
- MySQL CLI

## Setup

1. Clone this repository:
    ```bash
    git clone https://github.com/bbarclay/docker_purge_s3.git
    ```
2. Change into the repository directory:
    ```bash
    cd repo
    ```
3. Edit the `.env` file to include your AWS and MySQL credentials:
    ```bash
    nano .env
    ```
    Be sure to replace the placeholders with your actual credentials. 
    Save and close the file when you're done editing.

## Usage

### Backup and Purge

The `backup_and_purge.sh` script is used to backup and purge Docker containers that are older than 15 days.

Run the script without any options to simply backup and purge the containers and volumes:

```bash
./backup_and_purge.sh
```

You can also use the `-r` option to remove the Docker images:

```bash
./backup_and_purge.sh -r
```

### Restore

The `restore.sh` script is used to restore a Docker container and its volumes from a backup.

To use this script, pass the ID of the backup record from the MySQL database:

```bash
./restore.sh -i 123
```

Replace `123` with the actual ID.

### Scheduling

You can schedule the `backup_and_purge.sh` script to run at a certain time every day using cron.

For example, to run the script every day at 2 AM:

```cron
0 2 * * * /path/to/backup_and_purge.sh -r >> /path/to/logfile.log 2>&1
```

Replace `/path/to/backup_and_purge.sh` with the actual path to the `backup_and_purge.sh` script, and `/path/to/logfile.log` with the actual path to the log file.

#Be sure to set the correct permissions on the script file:

```bash
chmod +x backup_and_purge.sh
```

## The Database Table Schema is located in the backups.sql file
```SQL
CREATE TABLE backups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    container_id VARCHAR(64) NOT NULL,
    container_name VARCHAR(255) NOT NULL,
    image VARCHAR(255) NOT NULL,
    volume_name VARCHAR(255) NOT NULL,
    s3_path VARCHAR(255) NOT NULL
);
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
