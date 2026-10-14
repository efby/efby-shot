#!/usr/bin/env python3
"""Choose the next repository version after a PR merge."""
import os
import plistlib
import re
import subprocess
from pathlib import Path


def next_version(base: str, tags: list[str]) -> str:
    current = tuple(map(int, base.split(".")))
    versions = [tuple(map(int, tag[1:].split("."))) for tag in tags
                if re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", tag)]
    if versions and max(versions) >= current:
        major, minor, patch = max(versions)
        current = (major, minor, patch + 1)
    return ".".join(map(str, current))


def main() -> None:
    base = plistlib.loads(Path("Resources/Info.plist").read_bytes())["CFBundleShortVersionString"]
    tags = subprocess.check_output(["git", "tag", "--list", "v*"], text=True).splitlines()
    version = next_version(base, tags)
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as output:
        output.write(f"MONITORSHOT_APP_VERSION={version}\n")
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
        output.write(f"tag=v{version}\ncommit={commit}\n")
    print(f"EFBY Monitor Shot v{version}, commit {commit}")


if __name__ == "__main__":
    main()
