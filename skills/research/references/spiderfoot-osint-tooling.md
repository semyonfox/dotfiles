# SpiderFoot OSINT Tooling Setup

Use this when the user asks to install/configure SpiderFoot for lightweight OSINT automation, especially phone-number or nuisance-call investigations.

## Install path preference

Prefer an isolated local install over system Python:

```bash
mkdir -p ~/tools
cd ~/tools
wget -q -O /tmp/spiderfoot-v4.0.tar.gz https://github.com/smicallef/spiderfoot/archive/v4.0.tar.gz
tar -xzf /tmp/spiderfoot-v4.0.tar.gz
cd spiderfoot-4.0
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
```

SpiderFoot 4.0's original `pyyaml>=5.4.1,<6` can fail to build on modern Python 3.11+ runtimes. Preserve upstream requirements but create a local runtime-specific file:

```bash
python - <<'PY'
from pathlib import Path
req = Path('requirements.txt').read_text()
req = req.replace('pyyaml>=5.4.1,<6', 'pyyaml>=6.0.2,<7')
Path('requirements.local-py311.txt').write_text(req)
PY
pip install -r requirements.local-py311.txt
```

Verify:

```bash
python ./sf.py -V
python ./sf.py -M | wc -l
```

## Local launcher

Create a wrapper rather than relying on shell cwd/state:

```bash
mkdir -p ~/.local/bin
cat > ~/.local/bin/spiderfoot-local <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/tools/spiderfoot-4.0"
source .venv/bin/activate
exec python ./sf.py -l "${SPIDERFOOT_LISTEN:-127.0.0.1:5001}" "$@"
SH
chmod +x ~/.local/bin/spiderfoot-local
```

Start and verify:

```bash
spiderfoot-local
curl -fsS http://127.0.0.1:5001/ >/dev/null
```

SpiderFoot stores config/data in `~/.spiderfoot/spiderfoot.db`.

## Easy free/no-key add-ons

Install and wire local tools that do not require API keys:

```bash
cd ~/tools/spiderfoot-4.0
source .venv/bin/activate
pip install dnstwist wafw00f snallygaster
npm install --no-audit --no-fund retire
```

Set module option paths through `/opts`/`/savesettingsraw`. Important: SpiderFoot's raw settings API expects colon-form internal keys, not the display keys shown by `/optsraw`.

Useful key mapping:

```json
{
  "_maxthreads": "6",
  "sfp_tool_dnstwist:dnstwistpath": "$HOME/tools/spiderfoot-4.0/.venv/bin/dnstwist",
  "sfp_tool_dnstwist:pythonpath": "$HOME/tools/spiderfoot-4.0/.venv/bin/python",
  "sfp_tool_wafw00f:wafw00f_path": "$HOME/tools/spiderfoot-4.0/.venv/bin/wafw00f",
  "sfp_tool_wafw00f:python_path": "$HOME/tools/spiderfoot-4.0/.venv/bin/python",
  "sfp_tool_snallygaster:snallygaster_path": "$HOME/tools/spiderfoot-4.0/.venv/bin/snallygaster",
  "sfp_tool_retirejs:retirejs_path": "$HOME/tools/spiderfoot-4.0/node_modules/.bin/retire"
}
```

After save, verify through `/optsraw`; display keys should become:

- `global._maxthreads`
- `module.sfp_tool_dnstwist.dnstwistpath`
- `module.sfp_tool_wafw00f.wafw00f_path`
- `module.sfp_tool_snallygaster.snallygaster_path`
- `module.sfp_tool_retirejs.retirejs_path`

## API-key handling

Do not ask the user to paste OSINT API keys into chat. If keys are already present locally, report only provider names, never values. Otherwise direct the user to add keys in `http://127.0.0.1:5001/opts` or store them in Vaultwarden first.

For multi-provider signup/key intake, use `references/osint-api-account-signup.md`: create pending vault items before signup, mark API keys as `PENDING` until confirmed, and only configure SpiderFoot after the key is actually present. Browser signup CAPTCHAs/Arkose challenges are common; report them as blockers rather than implying a pending item is a working integration.

Useful free/free-tier modules to suggest:

- AlienVault OTX: `sfp_alienvault`
- AbuseIPDB: `sfp_abuseipdb`
- VirusTotal public API: `sfp_virustotal`
- Shodan free account key: `sfp_shodan`
- SecurityTrails community/free: `sfp_securitytrails`
- GreyNoise community: `sfp_greynoise`
- FullHunt community/free: `sfp_fullhunt`
- URLScan: `sfp_urlscan` often works for public lookups without a key, key improves limits/submission
- AbstractAPI Phone Validation: `sfp_abstractapi.phonevalidation_api_key`
- NumVerify: `sfp_numverify`
- HaveIBeenPwned: `sfp_haveibeenpwned`, useful but API access is not broadly free

## Phone-number OSINT notes

SpiderFoot has `PHONE_NUMBER` target/event support, but phone-only scans are thin without phone enrichment APIs. For nuisance-call or wrong-number floods, combine SpiderFoot with manual exact/variant searches and caller-source logging. Low-noise starting modules are `sfp_phone`, then API-backed `sfp_abstractapi`, `sfp_numverify`, and `sfp_haveibeenpwned` if keys are available.
