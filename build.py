import json
import os
import shutil
import tarfile
import urllib.request
from pathlib import Path

BASE_DIR = Path(__file__).parent
BUILD_DIR = BASE_DIR / "build"
DOWNLOADS_DIR = BASE_DIR / "downloads"
BASE_MODULE_DIR = BASE_DIR / "base"
TMP_DIR = BUILD_DIR / "tmp"

GITHUB_RELEASE_URL = "https://github.com/Ahmeth4n/renef/releases/download"

# renef only ships ARM64 for Android
ARCH = "arm64"


def download_file(url: str, path: Path) -> None:
    if path.exists():
        print(f"  [cache] {path.name}")
        return
    print(f"  [download] {url}")
    path.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(url, path)


def extract_renef_archive(archive_path: Path, dest_dir: Path) -> None:
    """Extract renef_server and libagent.so from the tar.gz archive."""
    print(f"  [extract] {archive_path.name} -> {dest_dir}")
    dest_dir.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive_path, "r:gz") as tar:
        for member in tar.getmembers():
            filename = Path(member.name).name
            if filename in ("renef_server", "libagent.so"):
                member.name = filename  # flatten path
                tar.extract(member, path=dest_dir)


def generate_version_code(project_tag: str) -> int:
    """Convert '0.3.3-2' -> integer version code for Magisk."""
    base = project_tag.replace("-", ".")
    parts = base.split(".")
    # zero-pad each part to 3 digits, join
    try:
        return int("".join(p.zfill(3) for p in parts))
    except ValueError:
        return 0


def create_module_prop(path: Path, project_tag: str) -> None:
    version_code = generate_version_code(project_tag)
    update_json_url = "https://raw.githubusercontent.com/vichhka-git/magisk-renef/master/build/updater.json"
    content = f"""\
id=magisk-renef
name=MagiskRenef
version=v{project_tag}
versionCode={version_code}
author=vichhka
description=Renef server for Android (ARM64) — dynamic instrumentation via Magisk
updateJson={update_json_url}
"""
    path.write_text(content)


def create_module() -> None:
    """Copy base/ to build/tmp/."""
    if TMP_DIR.exists():
        shutil.rmtree(TMP_DIR)
    shutil.copytree(BASE_MODULE_DIR, TMP_DIR)
    print("[module] Base template copied to build/tmp/")


def fill_module(renef_tag: str, project_tag: str) -> None:
    """Download renef android arm64 release, extract binaries into module."""
    # Strip leading 'v' if present for URL construction
    clean_tag = renef_tag.lstrip("v")
    archive_name = f"renef-v{clean_tag}-android-{ARCH}.tar.gz"
    archive_url = f"{GITHUB_RELEASE_URL}/v{clean_tag}/{archive_name}"
    archive_path = DOWNLOADS_DIR / archive_name

    download_file(archive_url, archive_path)

    # Extract into a temp staging dir
    staging_dir = DOWNLOADS_DIR / f"renef-{clean_tag}-{ARCH}"
    extract_renef_archive(archive_path, staging_dir)

    # Place binaries into module
    bin_dir = TMP_DIR / "system" / "bin"
    lib_dir = TMP_DIR / "system" / "lib64"
    bin_dir.mkdir(parents=True, exist_ok=True)
    lib_dir.mkdir(parents=True, exist_ok=True)

    server_src = staging_dir / "renef_server"
    agent_src = staging_dir / "libagent.so"

    if server_src.exists():
        shutil.copy2(server_src, bin_dir / "renef_server")
        print(f"  [module] renef_server -> system/bin/")
    else:
        print(f"  [warn] renef_server not found in archive!")

    if agent_src.exists():
        shutil.copy2(agent_src, lib_dir / "libagent.so")
        print(f"  [module] libagent.so -> system/lib64/")
    else:
        print(f"  [warn] libagent.so not found in archive!")

    # Write module.prop
    create_module_prop(TMP_DIR / "module.prop", project_tag)
    print(f"  [module] module.prop written (v{project_tag})")


def create_updater_json(project_tag: str) -> None:
    version_code = generate_version_code(project_tag)
    zip_url = (
        f"https://github.com/vichhka-git/magisk-renef/releases/download"
        f"/{project_tag}/MagiskRenef-{project_tag}.zip"
    )
    changelog_url = "https://github.com/Ahmeth4n/renef/releases"
    data = {
        "version": f"v{project_tag}",
        "versionCode": version_code,
        "zipUrl": zip_url,
        "changelog": changelog_url,
    }
    out_path = BUILD_DIR / "updater.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(data, indent=2))
    print(f"[updater] updater.json written")


def package_module(project_tag: str) -> None:
    """Zip build/tmp/ into MagiskRenef-{tag}.zip."""
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    zip_name = f"MagiskRenef-{project_tag}"
    zip_path = BUILD_DIR / zip_name

    import zipfile

    output_zip = BUILD_DIR / f"{zip_name}.zip"
    skip_names = {"placeholder", ".gitkeep"}

    with zipfile.ZipFile(output_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for file_path in TMP_DIR.rglob("*"):
            if file_path.is_dir():
                continue
            if file_path.name in skip_names:
                continue
            arcname = file_path.relative_to(TMP_DIR)
            zf.write(file_path, arcname)

    print(
        f"[package] {output_zip.name} created ({output_zip.stat().st_size // 1024} KB)"
    )


def do_build(renef_tag: str, project_tag: str) -> None:
    print(f"\n=== Building MagiskRenef v{project_tag} (renef v{renef_tag}) ===\n")

    DOWNLOADS_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_DIR.mkdir(parents=True, exist_ok=True)

    create_module()
    fill_module(renef_tag, project_tag)
    create_updater_json(project_tag)
    package_module(project_tag)

    print(f"\n=== Build complete ===")
    print(f"  ZIP : build/MagiskRenef-{project_tag}.zip")
    print(f"  JSON: build/updater.json")
