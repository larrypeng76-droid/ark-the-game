# Tools (Lint/Gates)

Run all basic gates:

```bash
./tools/lint.sh
```

Environment overrides:

- `GODOT_BIN=/path/to/Godot` to point at a non-default Godot binary.
- `GODOT_LOG_DIR=/some/dir` to place log files elsewhere.

Notes:

- In this Codex sandbox, Godot headless should always use `--log-file` (these scripts do).
- `./tools/lint_architecture.sh` is warnings-only by default; use `STRICT=1` to fail on warnings.

