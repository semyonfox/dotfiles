# Jenkins managed-pipeline source triage

Use when a pushed repository `Jenkinsfile` does not change the behaviour of the Jenkins job.

## Principle

The repository being built and the repository/configuration that **defines** the Jenkins job may be different. Do not assume the checked-out app's `Jenkinsfile` is active.

## Diagnosis

1. Read the failing build log and record its real stages, shell commands, checked-out SHA, and failure point.
2. Compare those commands with the app-repo `Jenkinsfile`.
3. On the Jenkins host, inspect the job configuration, e.g. `.../jobs/<job>/config.xml`, and identify the stored pipeline script.
4. Inspect seed Job DSL / init Groovy and its referenced pipeline root. A seed script that calls `new CpsFlowDefinition(scriptFile.text, true)` copies the script into the job configuration at seed time; editing the app repo alone will not update it.
5. Patch the authoritative pipeline source, keep any app-repo copy documented/synchronised if it is retained, and persist the authoritative source in its own repository.

## Reload and verify

1. Confirm no important builds are running.
2. Reload the seed mechanism (often a controlled Jenkins container recreation/restart) and wait for the Jenkins-ready signal.
3. Verify the new command/text is present in the job `config.xml` before retriggering.
4. Trigger the normal GitHub-push path or a correctly authenticated Jenkins build. Avoid claiming success from a local build alone.
5. Poll the resulting build's final result and inspect its checked-out SHA.
6. Probe the deployed service and required dependencies separately (HTTP response, health endpoint, container health).

## Docker-network pitfall

A Jenkins container's bridge gateway (for example `172.x.x.1`) is not automatically the host's production database listener. Test connectivity from the Jenkins network namespace before changing CI:

```bash
docker run --rm --network container:<jenkins-container> postgres:13 \
  pg_isready -t 3 -h <candidate-host> -p 5432
```

Use the confirmed host address or an explicit, documented Docker network attachment; do not guess from the bridge gateway.

## Build-image pitfall

Minimal Node/Debian images may lack a populated CA bundle. If a Rust-backed build tool panics while initialising HTTPS with an error like “No CA certificates were loaded”, install `ca-certificates` in the **builder** stage and rerun the exact Docker build.
