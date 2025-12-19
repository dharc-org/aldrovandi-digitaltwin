## Useful commands for INTEL 

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

## Useful commands for Apple Silicon

```bash
# Logs
docker compose -f docker-compose-arm.yml logs -f

# Stop
docker compose -f docker-compose-arm.yml down

# Stop and remove images
docker compose -f docker-compose-arm.yml down --rmi all

# Stop, remove images and volumes
docker compose -f docker-compose-arm.yml down --rmi all -v

# Rebuild single service
docker compose -f docker-compose-arm.yml build aton --no-cache
docker compose -f docker-compose-arm.yml up -d aton
```


## Troubleshooting

### "Cannot find module" error on ATON
Make sure the entrypoint.sh uses `npm start` and not `node ATON.js`.

### 3D files not found (404)
Verify that the contents are in `./aton-content/` and not in a subfolder.

### MELODY not reachable from browser
Check that `SERVER_HOST` in `.env` is correct and that the sed in the entrypoint has replaced the URLs.

### Case sensitivity .glb/.GLB files
Linux is case-sensitive. If the JSONs request `.GLB` but the files are `.glb`, rename the files or vice versa.

### GPG/signature error on macOS Apple Silicon
If during the build you see errors like "At least one invalid signature was encountered", clean the Docker cache:

```bash
docker builder prune -a -f
docker system prune -a -f
```

If it persists, from Docker Desktop go to Settings → Troubleshoot → "Clean / Purge data", then restart Docker Desktop.