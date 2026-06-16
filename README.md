# dst-server

Don't Starve Together dedicated server Docker image, published to `ghcr.io/casta-mere/dst-server`.

- **Overworld + Caves** two-shard cluster
- **Auto-updates** daily: checks DST server build ID via SteamCMD, rebuilds only when the game version changes
- **Mods** via Steam Workshop (`dedicated_server_mods_setup.lua` + `modoverrides.lua`)

## Quick start (NAS)

1. Get a Klei cluster token at https://accounts.klei.com/account/game/servers?game=DontStarveTogether
2. Edit `cluster/cluster.ini` — set `cluster_name`, `cluster_password`, `cluster_key`
3. Put your token in `cluster/cluster_token.txt` (never commit this file)
4. Add mods to `mods/dedicated_server_mods_setup.lua` and `cluster/*/modoverrides.lua`
5. Run:

```bash
docker compose pull
docker compose up -d
docker logs dst-master   # watch for "Master is up!"
docker logs dst-caves    # watch for "Caves is up!"
```

Players connect to `<NAS_IP>:10999`.

## Auto-sleep

Uses [Timid](https://github.com/fuglesteg/timid) — both shards sleep when idle and wake on the first connection.

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| 10999 | UDP | Overworld (Master shard) |
| 11000 | UDP | Caves shard |
| 12346–12347 | UDP | Steam networking |

## Mod setup

1. Find the mod's Steam Workshop URL: `https://steamcommunity.com/sharedfiles/filedetails/?id=<ID>`
2. Add `ServerModSetup("<ID>")` to `mods/dedicated_server_mods_setup.lua`
3. Add `["workshop-<ID>"] = { enabled = true }` to `cluster/Master/modoverrides.lua` and `cluster/Caves/modoverrides.lua`
4. Restart the containers
5. Players must subscribe to the same mods in Steam before joining
