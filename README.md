# Aldrovandi Ecosystem

Docker stack for the Aldrovandi DigitalTwin project.


Services:

- **Fuseki**: SPARQL endpoint with chad-kg dataset
- **MELODY**: Dashboard API (Python/Flask + Gunicorn)
- **ATON**: 3D Framework (Node.js)
- **Varnish**: Cache layer for static resources (CSS, JS, 3D assets, images)

---

## Setup on INTEL processors (with internet access)

### 1. Configure the environment

```bash
cp .env.example .env
vim .env
```

Edit everything you need in **.env** depending on your pc/server hardware availability.

### 2. Add the data

There are some custom files we need to grab from external sources, specifically the TTL files and the aldrovandi aton files.

First we need to add the new and updated TTLs (if available), so:

- TTL files in `./data/`:
  - `chad_kg.ttl`
  - `chad-ap.ttl`

Then we need to download the aton files for the aldrovandi project and put them in the aton-content folder, so:

- Aldrovandi contents in `./aton-content/`

### 3. Build the images

Now we can proceed with creating the images, this procedure needs to be repeated every time we change something in the entrypoints or modify the ports.

```bash
docker compose build --no-cache
```

### 4. Start the containers

Now we're ready to fire up our project, run the command:

```bash
docker compose up -d
```

Wait a couple of minutes, then you can reach our main service at this link:

http://127.0.0.1/a/aldrovandi

---

## Setup on ARM processors (like macOS Apple Silicon)

If you're using a Mac with Apple Silicon processor, you need to use the `docker-compose-arm.yml` file which is optimized for ARM architecture. Same goes if you're using a raspberry or any computer with an ARM processor, you need to use this setup.

### 1. Configure the environment

```bash
cp .env.example .env
vim .env
```

Edit everything you need in **.env** depending on your pc/server hardware availability.

### 2. Add the data

There are some custom files we need to grab from external sources, specifically the TTL files and the aldrovandi aton files.

First we need to add the new and updated TTLs (if available), so:

- TTL files in `./data/`:
  - `chad_kg.ttl`
  - `chad-ap.ttl`

Then we need to download the aton files for the aldrovandi project and put them in the aton-content folder, so:

- Aldrovandi contents in `./aton-content/`

### 3. Build the images (ARM native)

Now we can proceed with creating the images, this procedure needs to be repeated every time we change something in the entrypoints or modify the ports.

```bash
docker compose -f docker-compose-arm.yml build --no-cache
```

### 4. Start the containers

Now we're ready to fire up our project, run the command:

```bash
docker compose -f docker-compose-arm.yml up -d
```

Wait a couple of minutes, then you can reach our main service at this link:

http://127.0.0.1/a/aldrovandi


## Other documentation

For deploying the Digital Twin on an offline server, check out:
./docs/offline-installation.md

For useful commands and troubleshooting:
./docs/useful-cmd.md