#!/usr/bin/env python3
"""Validate canonical skill metadata and local links."""
from pathlib import Path
import json,re,sys
import yaml
root=Path('skills'); inv=json.loads(Path('docs/agent-skill-inventory.json').read_text())
expected={row['directory']:row['harness'] for row in inv}
files=sorted(p for p in root.rglob('SKILL.md') if '.system' not in p.parts)
valid=triggers=matches=0; errors=[]; links=[]
for p in files:
    text=p.read_text(); match=re.match(r'^---\n(.*?)\n---\n', text, re.S)
    if not match: errors.append(f'{p}: missing frontmatter'); continue
    try: data=yaml.safe_load(match.group(1))
    except yaml.YAMLError as exc: errors.append(f'{p}: YAML: {exc}'); continue
    valid += 1
    if str(data.get('description','')).startswith('Use when '): triggers += 1
    else: errors.append(f'{p}: description is not trigger-first')
    harness=(data.get('metadata') or {}).get('harness')
    name=p.parent.name
    if name in expected:
        if harness==expected[name]: matches+=1
        else: errors.append(f'{p}: harness mismatch')
    else:
        # Legacy canonical packages have no audit-map row; validate that a harness is present.
        if not isinstance(harness, list) or not harness: errors.append(f'{p}: legacy package lacks harness')
    for target in re.findall(r'(?<![\w.])((?:references|scripts|templates)/[A-Za-z0-9_./-]+)', text):
        if not (p.parent/target).exists(): links.append(f'{p}: {target}')
broken=[str(p) for p in root.rglob('*') if p.is_symlink() and not p.exists()]
print(json.dumps({'skill_md_total':len(files),'valid_yaml_frontmatter':valid,'trigger_first_descriptions':triggers,'inventory_packages':len(expected),'metadata_harness_exact_matches':matches,'missing_local_references':len(links),'broken_symlinks':len(broken),'noninventory_packages':sorted({p.parent.name for p in files}-set(expected)),'errors':errors,'missing_link_details':links,'broken_symlink_details':broken},indent=2))
sys.exit(bool(errors or broken or valid != len(files) or matches != len(expected)))
