# AWS backup credential recovery and tiny bill attribution

Session pattern captured from recovering Semyon's AWS credentials from NAS backups and identifying a ~$0.70 bill.

## Useful search target

The recovered AWS directory was found under a recycle/device-dump dotfiles backup:

```text
/mnt/media/users/semyon/.recycle/semyon/device_dumps/linux-laptop/home-dotfiles-current/.aws
```

This is not a permanent guarantee, but it is a strong hint for future searches: NAS backups can preserve dotfile directories under `.recycle/.../device_dumps/.../home-dotfiles-current/`.

## Practical lessons

- User may typo `.asw`; search both `.aws` and `.asw`.
- Full recursive searches over `/mnt/media/users/semyon` can time out on NFS. Split the search by likely subroots and use `timeout` per root.
- `cp -a` from NFS/backup paths into the active home may fail on permission preservation. Fall back to normal `cp`, then `chmod 700 ~/.aws` and `chmod 600 ~/.aws/config ~/.aws/credentials`.
- If AWS CLI is absent but `boto3` exists, use boto3 directly for STS identity and Cost Explorer.
- Cost Explorer calls should use `region_name='us-east-1'` even for accounts/profiles whose resources live elsewhere.
- Never print actual access keys/secrets in chat; show profile names, regions, account suffixes, and redacted lengths only.

## Example boto3 billing probe

```python
import boto3, configparser, datetime, pathlib

cp = configparser.RawConfigParser()
cp.read(pathlib.Path.home() / '.aws/credentials')
profiles = cp.sections()

today = datetime.date.today()
first_this = today.replace(day=1)
prev_last = first_this - datetime.timedelta(days=1)
prev_start = prev_last.replace(day=1)

for prof in profiles:
    sess = boto3.Session(profile_name=prof)
    account = sess.client('sts').get_caller_identity()['Account']
    ce = sess.client('ce', region_name='us-east-1')
    result = ce.get_cost_and_usage(
        TimePeriod={'Start': prev_start.isoformat(), 'End': first_this.isoformat()},
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}],
    )
    rows = []
    total = 0.0
    for group in result['ResultsByTime'][0].get('Groups', []):
        amount = float(group['Metrics']['UnblendedCost']['Amount'])
        if abs(amount) > 0.000001:
            rows.append((amount, group['Keys'][0]))
            total += amount
    print(prof, '****' + account[-4:], total, rows)
```

## Bill-shape example from this session

The ~$0.70 bill was not Route 53. It belonged to the `old-oghma` profile/account suffix `****3097` for June 2026:

```text
$0.6000  AmazonCloudWatch
$0.1400  Tax
$0.0001  Amazon S3
$0.0000  AWS Secrets Manager
```

Drilling by usage type/region showed CloudWatch alarm-monitor usage across multiple regions:

```text
$0.366667  eu-north-1  CloudWatch alarm monitor usage
$0.160000  us-east-1   CloudWatch alarm monitor usage
$0.073333  eu-west-1   CloudWatch alarm monitor usage
```

The durable takeaway is not these exact account amounts; it is the workflow: recover profiles, verify account identity, inspect previous closed billing month, group by service, then usage type and region before explaining the charge.
