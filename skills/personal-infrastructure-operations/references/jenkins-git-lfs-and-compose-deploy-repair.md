# Jenkins Git LFS checkout and Compose deployment repair

Use when a Jenkins Pipeline can clone a private GitHub repository but fails during `git checkout` with a Git LFS smudge error such as `batch response: Bad credentials`, or when tests/builds later reach deployment failures.

## Diagnose in order

1. Read the latest Jenkins build log from the Jenkins volume. Establish the exact stage: checkout, tests, image build, or deploy.
2. Do not assume a successful ordinary Git fetch proves LFS works. Test a current GitHub credential against `git lfs fetch` in a disposable clone without printing the token.
3. If small build-critical LFS assets are the trigger, prefer moving those specific assets back to normal Git and adding a narrow later `.gitattributes` exception. Verify the staged blobs have their real byte size, not LFS pointer content, before committing.
4. For assets that must remain in LFS, make the Pipeline skip initial LFS smudging and perform an explicit authenticated `git lfs pull` using Jenkins `withCredentials`; do not expose the token in shell tracing or Git config.
5. Only treat a build as successful after the log ends with `Finished: SUCCESS`. Intermediate test-suite `<result>SUCCESS</result>` data can appear while a later build/deploy stage is still running.

## Database smoke tests from Jenkins

- Inspect the actual application container's `PG_HOST`, port, user, database, and network memberships with secret values redacted.
- Do not target an arbitrary host-bound PostgreSQL port: another database service may own it.
- Attach Jenkins to the app's Docker network declaratively in its Compose stack, then use the internal service DNS name (for example `pg-db:5432`). Validate `docker compose config -q`, resolve the service name from Jenkins, and verify TCP reachability.

## Compose deployment name conflicts

A pipeline can build both images successfully but fail at deploy with `container name ... is already in use` when a live container was created outside the current Compose project.

1. Inspect the conflicting container's Compose labels, image ID, ports, networks, and restart policy.
2. Tag its image with timestamped local rollback tags.
3. Remove only the named conflicting containers, then recreate them with the authoritative Compose stack.
4. Re-run the normal Jenkins pipeline; do not declare success from manual recreation alone.
5. Probe the live frontend and backend health endpoint afterward.

## Verification checklist

- Latest log has `Finished: SUCCESS` for the target revision.
- No LFS credential, database-authentication, or container-name-conflict markers occur in that build.
- The application services are current Compose-managed containers.
- Frontend HTTP and backend health/database probes succeed.
- Temporary credential-rotation files, test clones, and encrypted credential backups are removed once verification is complete.
