# jj colocated Git workflow

Use this when adding Jujutsu (`jj`) to an existing Git repo that should remain usable by Git tooling.

## Safe setup sequence

1. Identify the intended repository and inspect existing Git state first:

   ```bash
   git -C /path/to/repo rev-parse --show-toplevel
   git -C /path/to/repo status --short --branch
   git -C /path/to/repo remote -v | cat
   test -d /path/to/repo/.jj && echo JJ_EXISTS || true
   ```

2. Install `jj` if absent using the user's available native toolchain. With Rust/Cargo:

   ```bash
   cargo install --locked jj-cli
   jj --version
   ```

3. Initialize colocated jj without deleting or moving the Git repo:

   ```bash
   jj git init --colocate /path/to/repo
   ```

4. Configure repo-local identity from Git's existing identity, then update the current working-copy author if jj created it before the config was set:

   ```bash
   jj -R /path/to/repo config set --repo user.name "$(git -C /path/to/repo config --get user.name)"
   jj -R /path/to/repo config set --repo user.email "$(git -C /path/to/repo config --get user.email)"
   jj -R /path/to/repo metaedit --update-author
   ```

5. Correct `trunk()` if jj guesses the wrong default branch. For a repo whose active integration branch is `dev`:

   ```bash
   jj -R /path/to/repo config set --repo 'revset-aliases."trunk()"' 'dev@origin'
   ```

   The quotes around `"trunk()"` matter; unquoted TOML keys with parentheses fail.

6. Track the remote bookmarks that matter:

   ```bash
   jj -R /path/to/repo bookmark track dev --remote=origin
   jj -R /path/to/repo bookmark track main --remote=origin
   ```

7. Verify both jj and Git views:

   ```bash
   jj -R /path/to/repo status
   jj -R /path/to/repo bookmark list
   jj -R /path/to/repo log -n 8
   git -C /path/to/repo status --short --branch
   ```

## Pitfalls

- Existing uncommitted Git changes are preserved, but after colocated init Git may show detached `HEAD`. That is expected: `jj status`, `jj log`, and `jj diff` become the primary working-copy interface.
- Do not automatically rebase existing user changes after setup. Report when the working copy is behind tracked trunk and give the user the explicit command, e.g. `jj rebase -r @ -d dev`.
- If `jj git init --colocate` sets `trunk()` to `main@origin` but the repo's active branch was `dev`, fix it repo-locally rather than leaving a misleading default.
- `jj config list` takes one optional name at a time; do not pass multiple config names in one command.
