# PostgreSQL in a nutshell

## This is the repository for the presentation PostgreSQL in a nutshell created by Isaac Vitor


It includes a complete PostgreSQL environment with pgAdmin using Docker Compose for development and learning.

## 📖 Presentation

The complete presentation is available in PDF format: [PostgreSQL in a nutshell](docs/postgresql-nutshell-presentation.pdf)


## 📋 Prerequisites

- Docker
- Docker Compose

## 🚀 How to run

### 1. Initial setup

Before running Docker Compose, you need to execute the setup script to create the necessary directories and configuration files.

#### On Linux/macOS:

```bash
# Give execution permission to the script
chmod +x setup.sh

# Run the setup script
./setup.sh
```

#### On Windows:

```cmd
# Run the setup script (as administrator if necessary)
setup.bat
```

### 2. Run the containers

After running the setup script, start the containers:

```bash
# Start the containers
docker-compose up -d

# Or to see logs in real time
docker-compose up
```

### 3. Access the services

- **PostgreSQL**: `localhost:5432`
  - User: `postgres`
  - Password: `postgres`
  - Database: `postgres`

- **pgAdmin**: http://localhost:8088
  - Email: `admin@admin.com`
  - Password: `postgres`

## 🛠️ Useful commands

```bash
# Stop the containers
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# View container logs
docker-compose logs

# View logs of a specific container
docker-compose logs postgres
docker-compose logs pgadmin

# Restart the containers
docker-compose restart
```

### 🧹 Cleanup (Complete removal)

To completely remove all containers, volumes, and data created by this project:

#### On Linux/macOS:

```bash
# Give execution permission to the cleanup script
chmod +x cleanup.sh

# Run the cleanup script
./cleanup.sh
```

#### On Windows:

```cmd
# Run the cleanup script
cleanup.bat
```

**⚠️ WARNING**: The cleanup scripts will permanently delete all PostgreSQL data and configurations. Use with caution!

## 📁 Project structure

```
postgresql-nutshell/
├── docker-compose.yml      # Container configuration
├── setup.sh               # Setup script for Linux/macOS
├── setup.bat              # Setup script for Windows
├── cleanup.sh             # Cleanup script for Linux/macOS
├── cleanup.bat            # Cleanup script for Windows
├── postgres/
│   ├── data/              # PostgreSQL data (created automatically)
│   ├── conf/              # PostgreSQL configurations (created automatically)
│   ├── servers.json       # pgAdmin server configuration (created by setup)
│   └── pgpass             # pgAdmin password file (created by setup)
└── README.md
```

## ⚠️ File permissions

### Linux/macOS

The `.sh` scripts need execution permission:

```bash
# Give execution permission to setup script
chmod +x setup.sh

# Give execution permission to cleanup script
chmod +x cleanup.sh

# Check permissions
ls -la setup.sh cleanup.sh
```

### Windows

The `.bat` files usually don't need special permissions, but may need to be run as administrator depending on the system configuration.

## 🔧 Customization

To customize the configurations, edit the `docker-compose.yml` file:

- Change service ports
- Modify passwords and users
- Add environment variables
- Configure additional volumes

## 📝 Important notes

- PostgreSQL data is persisted in the `postgres/data/` directory
- pgAdmin comes pre-configured with the PostgreSQL connection
- Containers are configured to restart automatically
- Always run the setup script before first use

## 🆘 Troubleshooting

### Port already in use
If ports 5432 or 8088 are already in use, change them in `docker-compose.yml`:

```yaml
ports:
  - "5433:5432"  # PostgreSQL on port 5433
  - "8089:80"    # pgAdmin on port 8089
```

### Permission issues
On Linux/macOS, make sure the user has permission to create directories and files in the project directory.

### Containers don't start
Check if Docker is running and if you executed the setup script before `docker-compose up`.