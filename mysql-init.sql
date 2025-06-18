-- Set root password if not already set
ALTER USER 'root'@'localhost' IDENTIFIED BY 'simple_password';
ALTER USER 'root'@'%' IDENTIFIED BY 'simple_password';

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS launchpad_db;
USE launchpad_db;

-- Create licenses table
CREATE TABLE IF NOT EXISTS licenses (
    id INT(11) NOT NULL AUTO_INCREMENT,
    email VARCHAR(120) NULL,
    licensekey VARCHAR(120) NOT NULL,
    remaining INT(11) NULL DEFAULT 5,
    purchaseinfo TEXT NULL,
    purchasedate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    uid INT(11) NOT NULL AUTO_INCREMENT,
    key_id INT(11) NOT NULL,
    machine_id VARCHAR(120) NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (uid),
    FOREIGN KEY (key_id) REFERENCES licenses(id)
);

-- Create user with proper authentication method
CREATE USER IF NOT EXISTS 'launchpad_user'@'%' IDENTIFIED WITH caching_sha2_password BY 'launchpad_password';

-- Grant permissions to the user from any host
GRANT ALL PRIVILEGES ON launchpad_db.* TO 'launchpad_user'@'%';
FLUSH PRIVILEGES; 