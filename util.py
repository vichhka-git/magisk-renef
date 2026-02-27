import subprocess

import requests


def strip_revision(tag: str) -> str:
    """Strip revision suffix: '0.3.3-2' -> '0.3.3'"""
    parts = tag.split("-")
    # If last part is a pure integer, it's a revision
    if len(parts) > 1 and parts[-1].isdigit():
        return "-".join(parts[:-1])
    return tag


def get_last_github_tag(project_name: str) -> str:
    response = requests.get(
        f"https://api.github.com/repos/{project_name}/releases/latest",
        headers={"Accept": "application/vnd.github.v3+json"},
        timeout=30,
    )
    response.raise_for_status()
    tag = response.json()["tag_name"]
    # Strip leading 'v' if present
    return tag.lstrip("v")


def get_last_renef_tag() -> str:
    return get_last_github_tag("Ahmeth4n/renef")


def get_last_project_tag() -> str:
    return get_last_tag([])


def sort_tags(tags: list[str]) -> list[str]:
    def sort_key(tag: str):
        base = strip_revision(tag)
        parts = base.split("-")[0].split(".")
        try:
            return [int(p) for p in parts]
        except ValueError:
            return [0]

    return sorted(tags, key=sort_key)


def get_last_tag(filter_args: list[str]) -> str:
    tags_raw = exec_git_command(["tag", "-l"] + filter_args)
    tags = [t.strip() for t in tags_raw.splitlines() if t.strip()]
    if not tags:
        return ""
    return sort_tags(tags)[-1]


def exec_git_command(command_with_args: list[str]) -> str:
    result = subprocess.run(
        ["git"] + command_with_args,
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout


def get_next_revision(current_tag: str) -> str:
    """Find the next available revision tag for current_tag.
    e.g. if '0.3.3-1' exists, returns '0.3.3-2'
    """
    revision = 1
    while True:
        candidate = f"{current_tag}-{revision}"
        existing = get_last_tag([candidate])
        if not existing:
            return candidate
        revision += 1
