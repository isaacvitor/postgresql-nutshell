@echo off

REM Parar containers se estiverem rodando
docker-compose down postgres pgadmin

REM Criar diretórios necessários
mkdir postgres\conf 2>nul
mkdir postgres\data 2>nul

REM Criar arquivo de configuração do pgAdmin
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

REM Criar arquivo de senhas do pgAdmin
echo postgres:5432:*:postgres:postgres > postgres\pgpass

echo Diretórios e arquivos criados com sucesso!