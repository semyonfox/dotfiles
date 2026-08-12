# Geekbench upload `unknown error (internal code 35)`

## Context captured from a server benchmark session

Benchmark target:

- Hostname: `server`
- OS: Ubuntu 24.04.4 LTS, kernel `6.8.0-124-generic`
- CPU: Intel Core i7-8750H, 6 cores / 12 threads
- GPU: NVIDIA GeForce GTX 1050 Ti with Max-Q Design
- Geekbench: 6.6.0 Linux tarball from `https://cdn.geekbench.com/Geekbench-6.6.0-Linux.tar.gz`

Commands that ran successfully:

```bash
cd /tmp/Geekbench-6.6.0-Linux
./geekbench6 --gpu-list
./geekbench6 --cpu 2>&1 | tee /tmp/geekbench_cpu_$(date +%Y%m%d_%H%M%S).log
./geekbench6 --gpu OpenCL --gpu-platform-id 0 --gpu-device-id 0 \
  2>&1 | tee /tmp/geekbench_compute_opencl_$(date +%Y%m%d_%H%M%S).log
```

Observed GPU list:

```text
OpenCL: NVIDIA GeForce GTX 1050 Ti with Max-Q Design
Vulkan: NVIDIA GeForce GTX 1050 Ti with Max-Q Design; llvmpipe
```

Both CPU and OpenCL workloads completed, then failed during result upload:

```text
Uploading results to the Geekbench Browser. This could take a minute or two
depending on the speed of your internet connection.

 unknown error (internal code 35)
```

Direct endpoint checks from that egress returned Cloudflare challenge / 403:

```bash
curl -I -L -s -o /dev/null -w '%{http_code} %{url_effective}\n' https://browser.geekbench.com/
# 403 https://browser.geekbench.com/

curl -L -s https://browser.geekbench.com/ | sed -n '1,25p'
# HTML containing: <title>Just a moment...</title> and challenges.cloudflare.com
```

## Interpretation

This means the benchmark binaries could run, but Geekbench Browser did not accept/publish the upload from that server egress. No account-attachable browser URLs were generated.

## Reusable debugging pattern

1. Confirm the workload actually reached upload stage in the log.
2. Save log paths and do not invent share links.
3. Check `browser.geekbench.com` and `www.geekbench.com` with `curl -I -L`.
4. If challenged/403, rerun from a different outbound route or ask permission before changing server egress/VPN/exit-node settings.
5. If the user has Geekbench Pro, investigate offline/export or configurable browser upload options, but do not assume a license.
