# Security

This project is an early public release. Security fixes target the latest release; there is no guaranteed response SLA.

Use GitHub's **Security → Report a vulnerability** for a private report. Include the affected version, macOS version, reproduction steps and expected impact. Avoid publishing sensitive file contents, exploit details or personal paths in public issues. Ordinary bugs can go to Issues.

Download binaries only from this repository's Releases page and verify the included SHA-256 checksum when needed. Current binaries are signed ad hoc and are not notarized by Apple; see the installation notice in the README.

Mac Explorer uses macOS file permissions and the system Trash. Name collisions and symlink boundaries are part of the filesystem checks. The app is a file manager with real write access to files the user can access; a local signature or passing tests does not guarantee the absence of bugs. Keep normal backups.
