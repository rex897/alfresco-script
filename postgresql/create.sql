CREATE ROLE alfresco WITH LOGIN PASSWORD 'admin';
CREATE DATABASE alfresco;
GRANT ALL PRIVILEGES ON DATABASE alfresco TO alfresco;
CREATE DATABASE notifications WITH OWNER = alfresco;
CREATE DATABASE reporting WITH OWNER = alfresco;
