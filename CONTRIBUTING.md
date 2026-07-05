# Contributing

Thanks for your interest in the project.

## Rules

- Keep changes simple and readable.
- Do not hardcode private IPs, passwords, or real production paths.
- Add or update docs when behavior changes.
- Keep commit messages short and human-readable.

## Before opening a pull request

Run:

```bash
bash -n bin/* lib/* install.sh uninstall.sh
```

If `shellcheck` is installed, run:

```bash
shellcheck bin/* lib/* install.sh uninstall.sh
```
