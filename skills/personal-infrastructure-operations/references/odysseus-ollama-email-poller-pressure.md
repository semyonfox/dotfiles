# Odysseus email poller hammering Ollama

Use this reference when server load is high and Ollama is consuming CPU, especially with `gemma3:4b` or another local model loaded unexpectedly.

## Symptom pattern

- `uptime` load high but not necessarily full CPU starvation.
- `ps` shows `/usr/local/bin/ollama runner ...` at several hundred percent CPU.
- `ollama ps` shows a model loaded on `100% CPU`, often with a short unload timer that keeps renewing.
- Ollama journal shows repeated OpenAI-compatible API calls:
  - `POST /v1/chat/completions`
  - source IP in a Docker bridge subnet
  - long `90s` failures/timeouts and `client closing the connection`.
- Docker IP lookup maps the caller to `odysseus-odysseus-1`.
- Odysseus logs identify `routes.email_pollers` / auto-reply attempts failing against `http://10.0.0.5:11434/v1/chat/completions`.

## Read-only triage commands

```bash
uptime
free -h
ps -eo pid,ppid,user,stat,pcpu,pmem,etime,comm,args --sort=-pcpu | head -25
OLLAMA_HOST=127.0.0.1:11434 ollama ps
journalctl -u ollama --since '20 min ago' --no-pager | tail -120
sudo ss -tnp state established '( sport = :11434 or dport = :11434 or sport = :43065 or dport = :43065 )'
docker ps -q | xargs -r docker inspect --format '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}} {{.Config.Image}} {{.State.Status}}' | grep '<client-ip>'
docker logs --since 20m --tail 160 odysseus-odysseus-1
```

Redact API keys/tokens from `docker inspect` and logs before reporting.

## Safe mitigation used

If Semyon asks to keep Odysseus present but disable it for now:

```bash
docker update --restart=no odysseus-odysseus-1
docker stop odysseus-odysseus-1
docker inspect odysseus-odysseus-1 --format 'status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}} image={{.Config.Image}}'
docker ps -a --filter label=com.docker.compose.project=odysseus --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
```

This leaves the container, image, compose files, and sidecars in place. In the observed case the sidecars `odysseus-ntfy-1`, `odysseus-searxng-1`, and `odysseus-chromadb-1` stayed running.

After stopping Odysseus, unload the hot Ollama model if requested:

```bash
OLLAMA_HOST=127.0.0.1:11434 ollama stop gemma3:4b
sleep 3
OLLAMA_HOST=127.0.0.1:11434 ollama ps
pgrep -af 'ollama runner' || true
```

Verify there are no active Odysseus/Ollama connections and that CPU/load begins to fall. Swap may remain populated for a while; do not force `swapoff` unless the machine is still sluggish and Semyon approves the extra risk.

## Durable note

Current operational state from the session: `odysseus-odysseus-1` was intentionally stopped and set to restart policy `no` because its email auto-reply poller was hammering Ollama/gemma3 CPU. Re-enable only deliberately.