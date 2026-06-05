# Secrets

Do not commit plaintext secrets to this repository. The baseline tools are
installed now: `age` for recipients and `sops` for encrypted structured files.

## Policy

- Keep secret material encrypted at rest.
- Keep private age keys outside the repo.
- Commit only encrypted secret files.
- Prefer per-host recipients so one compromised host key does not expose every
  machine.

## Suggested Layout

Future encrypted files can live under `secrets/`, for example:

```text
secrets/
  laptop1.yaml
  common.yaml
```

That directory should contain only encrypted SOPS documents and a README. Add a
NixOS secret integration such as `sops-nix` only when there is a real secret to
deploy; otherwise it adds moving parts without protecting anything.

## Create An Age Recipient

```sh
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Use the public recipient in `.sops.yaml` when secrets are introduced.
