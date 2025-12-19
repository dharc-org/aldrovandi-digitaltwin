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
aldrovandi/varnish   local    ...
```

#### 3. Export the images as .tar files

```bash
docker save aldrovandi/fuseki:local -o aldrovandi-fuseki.tar
docker save aldrovandi/melody:local -o aldrovandi-melody.tar
docker save aldrovandi/aton:local -o aldrovandi-aton.tar
docker save aldrovandi/varnish:local -o aldrovandi-varnish.tar
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
├── aldrovandi-varnish.tar.gz
├── aldrovandi-ecosystem/
│   ├── docker-compose.yml
│   ├── .env
│   ├── aton/
│   ├── melody/
│   ├── fuseki/
│   ├── varnish/
│   └── data/
│   └── aton-content/
         └── (all 3D contents, audio, images)
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
docker load -i aldrovandi-varnish.tar
```

If you have the compressed `.tar.gz` files:
```powershell
docker load -i aldrovandi-fuseki.tar.gz
docker load -i aldrovandi-melody.tar.gz
docker load -i aldrovandi-aton.tar.gz
docker load -i aldrovandi-varnish.tar.gz
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

Edit `C:\aldrovandi-ecosystem\.env`:

Set the desired values and modify what you need.

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

- **Via Varnish (recommended)**: `http://SERVER_HOST/a/aldrovandi`
- **ATON direct**: `http://SERVER_HOST:8080/a/aldrovandi`
- **MELODY direct**: `http://SERVER_HOST:5010/melody/`
- **Fuseki**: `http://SERVER_HOST:3030/`

---

## Varnish Cache

Configured TTLs:
- CSS/JS/fonts: 7 days
- 3D assets (.gltf, .glb, .obj): 14 days
- Audio/Video: 7 days
- JSON/API: 5 minutes
- HTML: 1 minute

Check cache (response header):
- `X-Cache: HIT` = served from cache
- `X-Cache: MISS` = passed to backend

Clear cache:
```bash
docker exec aldrovandi-varnish varnishadm "ban req.url ~ ."
```

---

## Useful commands

### Logs
```bash
docker compose logs -f varnish
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