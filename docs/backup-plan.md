# Backup Plan

Backups are not configured automatically yet because the repository, retention,
password source, and off-machine target need to be chosen explicitly. The
standard tool for this setup is `restic`, installed through Home Manager.

## Scope

Back up user data, machine-specific notes, and this NixOS repository:

- `/home/oliver/Documents`
- `/home/oliver/Pictures`
- `/home/oliver/Music`
- `/home/oliver/Projects`
- `/home/oliver/.ssh`
- `/home/oliver/.gnupg`
- `/etc/nixos`

Exclude caches and generated state:

- `/home/oliver/.cache`
- `/home/oliver/.local/share/Trash`
- `/home/oliver/.var/app/*/cache`
- build outputs such as `target`, `node_modules`, `.direnv`, and `.venv`

## Policy

- Use an encrypted restic repository.
- Keep at least one copy off the laptop.
- Test restore after initial setup and after changing the backup scope.
- Do not store the restic repository password in plaintext in this repo.

## Manual Baseline

Initialize the repository once:

```sh
restic -r <repository> init
```

Run a backup:

```sh
restic -r <repository> backup \
  /home/oliver/Documents \
  /home/oliver/Pictures \
  /home/oliver/Music \
  /home/oliver/Projects \
  /home/oliver/.ssh \
  /home/oliver/.gnupg \
  /etc/nixos
```

Apply retention:

```sh
restic -r <repository> forget --prune \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12
```

Verify restore:

```sh
restic -r <repository> restore latest --target /tmp/restic-restore-test
```

## Declarative Follow-Up

After choosing a real repository and secret source, add a NixOS
`services.restic.backups.<name>` job with a timer and retention policy.
