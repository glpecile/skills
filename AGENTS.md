# Agent instructions

After cloning or pulling this repo, always run `./setup.sh` from the repo root before reporting the install as done. Cloning alone installs nothing: the skills only load once `setup.sh` links `skills/*` into each agent's skills dir and installs the `manifest` entries.

Run it again after adding, renaming, or removing a skill, or editing `manifest`. It is idempotent. Without `bunx` it links the local skills and skips the manifest; report that skip to the user.
