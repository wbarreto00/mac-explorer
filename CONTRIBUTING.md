# Contributing

Thank you for helping improve Mac Explorer. Issues and discussions in English, Brazilian Portuguese and Spanish are welcome; keep source identifiers in English and update the three user-facing catalogs together.

For bugs, include the app version, macOS version, chip, view mode, expected behavior and reproducible steps. Prefer small disposable examples. Remove private names, paths and file contents from screenshots or logs. For security issues, see [SECURITY.md](SECURITY.md).

Before a pull request:

1. Explain the user-visible problem and keep the change focused.
2. Read [development notes](docs/DEVELOPMENT.md).
3. Run `./script/test.sh` and `./script/build_and_run.sh --build-only` on Apple Silicon.
4. Verify affected UI flows and languages in the actual packaged app.
5. Add regression checks for meaningful filesystem or state changes, especially collision, symlink and undo behavior.
6. Update the relevant documentation and changelog. Mention which environments were actually tested.

Do not commit generated apps, ZIPs, `.build`, local assistant configuration, test fixtures containing personal information, or signing credentials. Do not introduce telemetry or network services as incidental changes. Contributions are provided under the repository's MIT license.
