CREATE TABLE backups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    container_id VARCHAR(64) NOT NULL,
    container_name VARCHAR(255) NOT NULL,
    image VARCHAR(255) NOT NULL,
    volume_name VARCHAR(255) NOT NULL,
    s3_path VARCHAR(255) NOT NULL
);