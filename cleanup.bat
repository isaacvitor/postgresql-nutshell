@echo off

REM Stop and remove containers
docker-compose down

REM Remove Docker volumes
docker volume rm postgresql_pgadmin_data 2>nul

REM Remove created directories and files
rmdir /s /q postgres 2>nul

echo Cleanup completed! All data has been removed.