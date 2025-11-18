@echo off

REM Stop containers if they are running
docker-compose down postgres pgadmin

REM Create necessary directories
mkdir postgres\data 2>nul

REM Create pgAdmin configuration file
(
echo {
echo   "Servers": {
echo     "1": {
echo       "Name": "PostgreSQL Local",
echo       "Group": "Servers",
echo       "Host": "postgres",
echo       "Port": 5432,
echo       "MaintenanceDB": "postgres",
echo       "Username": "postgres",
echo       "PassFile": "/pgpass",
echo       "SSLMode": "prefer"
echo     }
echo   }
echo }
) > postgres\servers.json

REM Create pgAdmin password file
echo postgres:5432:*:postgres:postgres > postgres\pgpass

echo Directories and files created successfully!