#!/bin/bash

# Stop and remove containers
docker-compose down

# Remove Docker volumes
docker volume rm postgresql_pgadmin_data 2>/dev/null

# Remove created directories and files
rm -rf postgres/

echo "Cleanup completed! All data has been removed."