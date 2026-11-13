# ACPlugins - No Hesi-Style Traffic Points System

CSP online Lua script (client HUD) + optional AssettoServer C# plugin for global leaderboards.

## Files

- `overtake.lua` - CSP online Lua script (points & combo HUD, near-miss detection, personal bests, drift/wrong-way/speed-tier scoring, live top-10 leaderboard). Hosted as a public Gist.
- `cfg/csp_extra_options.ini` - Server config snippet referencing the Gist raw URL.
- `plugins/CustomOvertakePlugin/` - Optional .NET 8 server plugin scaffold.

## Gist (raw URL used by the server)

https://gist.githubusercontent.com/LemonSoupQ/f6fdffe9839c62572af0a8b666c3f388/raw/overtake.lua

## Setup

1. Ensure `EnableClientMessages: true` in `cfg/extra_cfg.yml`.
2. Copy `cfg/csp_extra_options.ini` into your server's `cfg/` (merge if it exists).
3. Restart the server. CSP downloads the script automatically when players join `main_layout`.

## Optional plugin build

```
cd plugins/CustomOvertakePlugin
dotnet build -c Release
```

Upload `bin/Release/net8.0/CustomOvertakePlugin.dll` to `plugins/CustomOvertakePlugin/` on the server and add `- CustomOvertakePlugin` under `EnablePlugins:` in `cfg/extra_cfg.yml`. Requires `AssettoServer.Shared.dll` from the server root (adjust HintPath in csproj).
