#!/usr/bin/env bash
# Read-only root filesystem accounting for a storage-capacity report.
set -euo pipefail
export LC_ALL=C

printf 'generated_at\t%s\n' "$(date --iso-8601=seconds)"
printf 'root_filesystem\n'
findmnt -no SOURCE,FSTYPE,OPTIONS /
df -hT /
printf '\nroot_tree_depth_2\n'
du -xhd2 / 2>/dev/null | sort -h
printf '\nvar_tree_depth_3\n'
du -xhd3 /var 2>/dev/null | sort -h
printf '\ndocker_root_tree\n'
docker info --format 'root={{.DockerRootDir}} driver={{.Driver}}'
du -xhd3 /var/lib/docker 2>/dev/null | sort -h
printf '\ndocker_logical_inventory\n'
docker system df -v
printf '\ndeleted_open_files\n'
lsof -nP +L1 2>/dev/null || true
printf '\next4_superblock\n'
tune2fs -l "$(findmnt -no SOURCE /)" 2>/dev/null | grep -E 'Block count:|Reserved block count:|Block size:|Reserved blocks uid:|Reserved blocks gid:' || true
