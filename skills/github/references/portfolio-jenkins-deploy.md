# Portfolio Jenkins deployment pattern

Use when working on `semyonfox/portfolio` or similar repos where the real deploy path is Jenkins-on-push rather than a persistent server git checkout.

## Durable lesson

Do not assume a manual SSH deploy script is authoritative. In this portfolio setup, the server path `~/portfolio` was a stale/root-owned placeholder, while Jenkins checks out `main` into its workspace and rebuilds the Docker Compose stack from the repo.

## Safe workflow

1. Fix and verify the real local repo under `~/code/personal/portfolio`.
2. Run project-native checks locally:
   - `pnpm run check`
   - `pnpm run build`
3. If `package.json` has a manual `deploy` script pointing at a stale server checkout, change it to a verification/reminder script rather than preserving a broken deploy path. Jenkins owns production deployment after push.
4. Push `main`.
5. Verify Jenkins actually triggered and finished successfully. Useful server-side signals:
   - Jenkins container logs show GitHub webhook and `Triggering #N` for `portfolio`.
   - Jenkins build log shows checkout of the pushed commit, Docker image build, compose up, and `Finished: SUCCESS`.
6. Probe live endpoints after Jenkins finishes, not before:
   - `https://semyon.ie/`
   - relevant changed pages, e.g. `/cv/`, `/cv.pdf`, `/cv.tex`
7. For browser-visible changes, open the page and check browser console errors and the actual interaction, not just HTTP 200.

## Pitfall

A successful `curl` immediately after a push may still be serving the previous container or cached asset. Pair HTTP probes with Jenkins build success and container/image creation time when deployment correctness matters.
