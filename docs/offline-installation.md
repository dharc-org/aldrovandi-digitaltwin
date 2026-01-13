## Export for offline environment (Windows 11)

If you need to deploy on an INTEL machine, for example Windows 11 without internet connection, follow these steps.

### On the Linux server (source)

#### 1. Build all images
```bash
docker compose build --no-cache
```

#### 2. Verify the created images
```bash
docker images | grep aldrovandi
```

Expected output:
```
aldrovandi/fuseki    local    ...
aldrovandi/melody    local    ...
aldrovandi/aton      local    ...
aldrovandi/apache    local    ...
```

#### 3. Export the images as .tar files
```bash
docker save aldrovandi/fuseki:local -o aldrovandi-fuseki.tar
docker save aldrovandi/melody:local -o aldrovandi-melody.tar
docker save aldrovandi/aton:local -o aldrovandi-aton.tar
docker save aldrovandi/apache:local -o aldrovandi-apache.tar
```

#### 4. (Optional) Compress to save space
```bash
gzip *.tar
```

This creates much smaller `.tar.gz` files.

#### 5. Prepare the files to copy

Copy to USB drive:
```
USB/
├── aldrovandi-fuseki.tar.gz
├── aldrovandi-melody.tar.gz
├── aldrovandi-aton.tar.gz
├── aldrovandi-apache.tar.gz
├── aldrovandi-ecosystem/
│   ├── docker-compose.yml
│   ├── .env
│   ├── apache/
│   ├── aton/
│   ├── melody/
│   ├── fuseki/
│   ├── data/
│   └── aton-content/
│        └── (all 3D contents, audio, images)
```

---

### On Windows 11 (offline destination)

#### Prerequisites

- Docker Desktop installed (download it first on a machine with internet)

#### 1. Open PowerShell as administrator

#### 2. Import the Docker images
```powershell
docker load -i aldrovandi-fuseki.tar
docker load -i aldrovandi-melody.tar
docker load -i aldrovandi-aton.tar
docker load -i aldrovandi-apache.tar
```

If you have the compressed `.tar.gz` files:
```powershell
docker load -i aldrovandi-fuseki.tar.gz
docker load -i aldrovandi-melody.tar.gz
docker load -i aldrovandi-aton.tar.gz
docker load -i aldrovandi-apache.tar.gz
```

Docker reads gzip files directly.

#### 3. Verify the images are loaded
```powershell
docker images | findstr aldrovandi
```

#### 4. Copy the project folder

Copy `aldrovandi-ecosystem/` wherever you prefer, for example:
```
C:\aldrovandi-ecosystem\
```

#### 5. Configure the .env file

Edit `C:\aldrovandi-ecosystem\.env` and set `SERVER_HOST`:

| Mode | SERVER_HOST |
|------|-------------|
| KIOSK (local) | `127.0.0.1` |
| VR (headset) | Your LAN IP (es: `192.168.1.100`) |

#### 6. Start the containers
```powershell
cd C:\aldrovandi-ecosystem
docker compose up -d
```

#### 7. Verify everything is running
```powershell
docker ps
```

You should see 4 containers running.

---

## Access

**KIOSK:** `https://127.0.0.1/a/aldrovandi/?usebackup=true&mode=kiosk`

**VR Mode:** `https://YOUR_LAN_IP/a/aldrovandi/?usebackup=true`

---

## Useful commands

### Logs
```bash
docker compose logs -f apache
docker compose logs -f aton
docker compose logs -f melody
docker compose logs -f fuseki
```

### Rebuild single service
```bash
docker compose build aton --no-cache
docker compose up -d aton
```

### Stop everything
```bash
docker compose down
```

### Stop and remove images
```bash
docker compose down --rmi all
```

### Stop and remove volumes (WARNING: deletes Fuseki data)
```bash
docker compose down -v
```

### Stop and remove everything (images + volumes)
```bash
docker compose down --rmi all -v
```