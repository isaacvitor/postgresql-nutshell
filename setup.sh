#!/bin/bash

# Stop containers if they are running
docker-compose down postgres pgadmin

# Create necessary directories
mkdir -p postgres/data

# Create pgAdmin configuration file
cat > postgres/servers.json << EOF
{
  "Servers": {
    "1": {
      "Name": "PostgreSQL Local",
      "Group": "Servers",
      "Host": "postgres",
      "Port": 5432,
      "MaintenanceDB": "postgres",
      "Username": "postgres",
      "PassFile": "/pgpass",
      "SSLMode": "prefer"
    }
  }
}
EOF

# Create pgAdmin password file
echo "postgres:5432:*:postgres:postgres" > postgres/pgpass
chmod 600 postgres/pgpass

echo "Directories and files created successfully!"