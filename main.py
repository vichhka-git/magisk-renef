import os

import build
import util


def main() -> None:
    last_renef_tag = util.get_last_renef_tag()
    print(f"Latest renef release : {last_renef_tag}")

    last_project_tag = util.get_last_project_tag()
    print(f"Latest project tag   : {last_project_tag or '(none)'}")

    force_release = os.environ.get("FORCE_RELEASE", "").lower() in ("1", "true", "yes")

    # Check if renef has updated since our last release
    last_renef_base = last_renef_tag.lstrip("v")
    last_project_base = (
        util.strip_revision(last_project_tag) if last_project_tag else ""
    )

    needs_update = force_release or (last_renef_base != last_project_base)

    if not needs_update:
        print("All good! No update needed.")
        # Still build with placeholder tag for artifact testing
        if os.environ.get("BUILD_ALWAYS", "").lower() in ("1", "true", "yes"):
            build.do_build(last_renef_tag, "0")
        return

    # Compute new project tag
    if last_project_base == last_renef_base:
        # Same renef version, bump revision
        new_project_tag = util.get_next_revision(last_renef_base)
    else:
        # New renef version, start at revision 1
        new_project_tag = f"{last_renef_base}-1"

    print(f"New project tag      : {new_project_tag}")

    # Write tag for GitHub Actions to pick up
    with open("NEW_TAG.txt", "w") as f:
        f.write(new_project_tag)

    build.do_build(last_renef_tag, new_project_tag)


if __name__ == "__main__":
    main()
