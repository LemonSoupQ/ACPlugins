# ACPlugins - No Hesi-Style Traffic Points System

CSP online Lua script (client HUD) + optional AssettoServer C# plugin scaffold.

## Files

- `overtake.lua` - CSP online Lua script (points & combo HUD, near-miss detection, personal bests, drift/wrong-way/speed-tier scoring, live top-10 leaderboard).
- `cfg/csp_extra_options.ini` - Server config snippet (script served over HTTP from the host).
- `cfg/overtake.lua` - Copy of the script for the server's cfg/ folder.
- `plugins/CustomOvertakePlugin/` - Optional .NET 8 server plugin scaffold (not buildable on self-contained servers).

## Setup (HTTP server approach)

CSP on this server can't fetch HTTPS/external files, so `overtake.lua` is served over HTTP from the Ubuntu host.

1. Ensure `EnableClientMessages: true` in `cfg/extra_cfg.yml`.
2. Upload `overtake.lua` to the server's `cfg/` folder.
3. Copy `cfg/csp_extra_options.ini` into the server's `cfg/` (merge if it exists).
4. Host `overtake.lua` over HTTP on the Ubuntu host (port 8090):
   ```bash
   mkdir -p /opt/overtake
   cp cfg/overtake.lua /opt/overtake/overtake.lua
   # systemd service (see below)
   ```
5. Open port 8090 in the firewall.
6. Restart the server. CSP downloads the script automatically when players join `main_layout`.

### systemd unit for the HTTP server
```ini
[Unit]
Description=Overtake Lua HTTP server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 8090 --directory /opt/overtake
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

When you update `overtake.lua`, copy it to both `cfg/` and `/opt/overtake/`, then restart.