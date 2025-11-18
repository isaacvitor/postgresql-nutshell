#!/bin/bash

# Parar containers se estiverem rodando
docker-compose down postgres pgadmin

# Criar diretórios necessários
mkdir -p postgres/conf
mkdir -p postgres/data

# Criar arquivo de configuração do pgAdmin
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

# Criar arquivo de senhas do pgAdmin
echo "postgres:5432:*:postgres:postgres" > postgres/pgpass
chmod 600 postgres/pgpass

echo "Diretórios e arquivos criados com sucesso!"