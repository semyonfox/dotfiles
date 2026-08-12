# Geekbench 6 upload debugging: isolated WARP container

Use this pattern when Geekbench 6 workloads complete but upload fails with `unknown error (internal code 35)` and the user wants official Geekbench Browser claim links.

## Observed durable pattern

On Semyon's server, Geekbench 6.6.0 and 6.5.0 completed CPU/OpenCL workloads but failed during Browser upload with:

```text
Uploading results to the Geekbench Browser...
unknown error (internal code 35)
```

Geekbench 5.5.1 successfully published `/v5/cpu/...` and `/v5/compute/...` claim links from the same host, so treat this as a GB6 publishing-path problem, not a benchmark execution problem.

## Safe egress test without touching host routing

Do not change the server's global routes/VPN just to test benchmark upload. A safer route is an isolated privileged Docker container with Cloudflare WARP via `wgcf`, mounting Geekbench and GPU/OpenCL devices into the container.

Setup outline:

```bash
mkdir -p ~/.cache/wgcf-warp ~/.local/bin
curl -L -o ~/.local/bin/wgcf \
  https://github.com/ViRb3/wgcf/releases/download/v2.2.31/wgcf_2.2.31_linux_amd64
chmod +x ~/.local/bin/wgcf
cd ~/.cache/wgcf-warp
~/.local/bin/wgcf register
~/.local/bin/wgcf generate
chmod 600 wgcf-account.toml wgcf-profile.conf
```

Container probe pattern:

```bash
docker run --rm --privileged --gpus all --device /dev/net/tun \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -v ~/.cache/wgcf-warp/wgcf-profile.conf:/etc/wireguard/wgcf.conf:ro \
  -v ~/.local/opt/Geekbench-6.6.0-Linux:/gb6:ro \
  -v /etc/OpenCL/vendors:/etc/OpenCL/vendors:ro \
  -v ~/geekbench-results:/results \
  debian:bookworm-slim bash -lc '
    set -euo pipefail
    apt-get update >/dev/null
    apt-get install -y --no-install-recommends \
      ca-certificates curl wireguard-tools iproute2 iptables procps \
      ocl-icd-libopencl1 clinfo >/dev/null
    cp /etc/wireguard/wgcf.conf /tmp/wgcf.conf
    sed -i "/^DNS = /d" /tmp/wgcf.conf
    wg-quick up /tmp/wgcf.conf
    curl -4 -s --max-time 15 https://ifconfig.me; echo
    /gb6/geekbench6 --gpu-list
    /gb6/geekbench6 --cpu 2>&1 | tee /results/gb6_cpu_warp_$(date +%Y%m%d_%H%M%S).log
  '
```

Notes:

- `--privileged` avoided container sysctl failures from `wg-quick` (`net.ipv4.conf.all.src_valid_mark`).
- Mount `/etc/OpenCL/vendors` and set `NVIDIA_DRIVER_CAPABILITIES=all` so Geekbench can see the NVIDIA OpenCL device.
- This changes routing only inside the container, not the host/homelab.
- In the observed session, WARP changed outbound IP but GB6 still failed with internal code 35. Record that as evidence, not as a universal impossibility.

## Reporting guidance

If GB6 still does not publish after an isolated alternate egress test:

- Say directly that no GB6 claim links were issued.
- Include the exact log paths.
- Offer concrete next routes: different real WAN/mobile hotspot, a live Tailscale exit node on another network, or Geekbench Pro/offline if the user has a license.
- Do not substitute GB5 links without clearly labelling them as Geekbench 5.